package lvm;

###########################################################################################
#
#                                         sbackup
#                                     LVM integration
#
###########################################################################################

use strict;
use warnings;
use init;
use logger;

use Exporter qw(import);
our @ISA = qw(Exporter);
our @EXPORT = qw(lvm_create_snapshot lvm_remove_snapshot);

##
## lvm_create_snapshot
##
sub lvm_create_snapshot {
	my ($p_job, $SB_TIMESTART, $source_path, $lvm_size, $lvm_fallback)=@_;
	
	## Check if lvm is available
	system($cmd_dpkg.' -l lvm2 >/dev/null 2>&1');
	if($? != 0){
		version_log('minor','lvm',$::backupserver_fqdn,"LVM is not installed.");
		return 1;
	}

	&f_output("DEBUG","Attempting to create LVM snapshot for path: \"$source_path\"");
	version_log('normal','lvm',$::backupserver_fqdn,"Attempting to create LVM snapshot....");
	update_history($p_job,"perf=(Snapshot) 0%","status==0,type==backup,start==".$SB_TIMESTART);
	my $error = 0;
	my $result = "";
	my $source_dir = "";
	
	## Get dir on source
	if($error == 0){
  	my $tmp = `$::cmd_df --output=target \"$source_path\"|tail -1 2>&1`;
  	chomp($tmp);
  	if($? == 0){
  		$source_dir = $source_path;
  		$source_dir =~ s/^$tmp//;
  	}else{
  		version_log('minor','lvm',$::backupserver_fqdn,"Could not get source directory.");
  		$error = 1;
  	}
	}
	
	## Get block device
	my $lvm_blockdevice = "";
	if($error == 0){
  	$lvm_blockdevice = `$::cmd_df --output=source \"$source_path\"|tail -1 2>&1`;
  	chomp($lvm_blockdevice);
  	if($? != 0){
  		version_log('minor','lvm',$::backupserver_fqdn,"Could not get block device.");
  		$error = 1;
  	}
	}
	
	## Check block device
	if($error == 0 && !-b $lvm_blockdevice){
		version_log('minor','lvm',$::backupserver_fqdn,"Failed to create snapshot: $lvm_blockdevice is not a block device.");
		$error = 1;
	}
	
	## Get LV name
	my $lv_name = "";
	if($error == 0){
		$lv_name = `$::cmd_lvs --noheadings -o lv_name $lvm_blockdevice 2>&1`;
		if($? == 0){
			$lv_name =~ s/^\s+|\s+$//g;
		}else{
			version_log('minor','lvm',$::backupserver_fqdn,"Source is not an LV, error: $?, $lv_name");
			$error = 1;
		}
	}
	
	## Block device found
	if($error == 0){
		if($lvm_blockdevice && $lv_name){
			version_log('normal','lvm',$::backupserver_fqdn,"LVM Logical volume found.\nLV Block Device: $lvm_blockdevice\nLV Name: $lv_name");
		}else{
			version_log('minor','lvm',$::backupserver_fqdn,"Internal error...");
			$error = 1;
		}
	}
	
	## Check and remove old snapshots
	if($error == 0){
		$result = `$::cmd_lvdisplay \"${lvm_blockdevice}_sbackup_${p_job}_snap\" 2>&1`;
		if($? == 0){
			## Snapshot exists
			version_log('normal','lvm',$::backupserver_fqdn,"Old snapshot found, attempting to remove...");
			## Check if snapshot is mounted
			system('mountpoint -q "/mnt/sbackup_'.${p_job}.'_snap" 2>&1');
			if($? == 0){
				## umount snapshot
				$result = `$::cmd_umount \"/mnt/sbackup_${p_job}_snap\" 2>&1`;
				if($? != 0){
					version_log('minor','lvm',$::backupserver_fqdn,"Failed to unmount old snapshot.\n$result");
					$error = 1;
				}
			}
			## Remove old snapshot
			if($error == 0){
  			$result = `$::cmd_lvremove -f \"${lvm_blockdevice}_sbackup_${p_job}_snap\" 2>&1`;
  			if($? != 0){
  				version_log('minor','lvm',$::backupserver_fqdn,"Failed to remove old snapshot.\n$result");
  				$error = 1;
  			}
  		}			
		}
	}
	
	## Create LVM snapshot
	if($error == 0){
		$result = `$::cmd_lvcreate -l${lvm_size}%FREE -s -n \"${lv_name}_sbackup_${p_job}_snap\" ${lvm_blockdevice} 2>&1`;
		if($? == 0){
			## Snapshot created
			if(!-d "/mnt/sbackup_${p_job}_snap"){
  			system("mkdir \"/mnt/sbackup_${p_job}_snap\"");
  			if($? != 0){
  				version_log('minor','lvm',$::backupserver_fqdn,"Failed to create mnt directory \"/mnt/sbackup_${p_job}_snap\"");
  				$error = 1;
  			}
  		}
			if($error == 0){
  			$result = `$::cmd_mount -oro \"${lvm_blockdevice}_sbackup_${p_job}_snap\" \"/mnt/sbackup_${p_job}_snap\"`;
  			if($? == 0){
  				version_log('normal','lvm',$::backupserver_fqdn,"Snapshot created successfully.");
  			}else{
  				version_log('minor','lvm',$::backupserver_fqdn,"Failed to mount snapshot\n$result");
  				$error = 1;
  			}
  		}
		}else{
			## Failed to create snapshot
			version_log('minor','lvm',$::backupserver_fqdn,"Failed to create a snapshot\n$result");
			$error = 1;
		}
	}	
	
	##
	## Error
	##
	if($error != 0){
		## Check LVM fallback
		if($lvm_fallback == 0){
			version_log('major','lvm',$::backupserver_fqdn,"Snapshot fallback is disabled, aborting.");
			::job_failed("Snapshot creation failed.");
		}
		version_log('warning','lvm',$::backupserver_fqdn,"Falling back to regular backup.");
	}
	
	$error = "/mnt/sbackup_${p_job}_snap".$source_dir if $error == 0;
	
	return $error;
}

##
## lvm_remove_snapshot
##
sub lvm_remove_snapshot {
	my ($p_job, $SB_TIMESTART, $source_path, $lvm_size, $lvm_fallback)=@_;

	&f_output("DEBUG","Attempting to remove LVM snapshot for path: \"$source_path\"");
	version_log('normal','lvm',$::backupserver_fqdn,"Removing LVM snapshot....");
	update_history($p_job,"perf=(Snapshot) 100%","status==0,type==backup,start==".$SB_TIMESTART);
	my $error = 0;
	my $result = "";
	
	## Get block device
	my $lvm_blockdevice = "";
	if($error == 0){
  	$lvm_blockdevice = `$::cmd_df --output=source \"$source_path\"|tail -1 2>&1`;
  	chomp($lvm_blockdevice);
  	if($? != 0){
  		version_log('minor','lvm',$::backupserver_fqdn,"Could not get source directory.");
  		$error = 1;
  	}
  }
	
	## Check block device
	if($error == 0 && !-b $lvm_blockdevice){
		version_log('minor','lvm',$::backupserver_fqdn,"Failed to remove snapshot: $lvm_blockdevice is not a block device.");
		$error = 1;
	}
	
	## Get LV name
	my $lv_name = "";
	if($error == 0){
		$lv_name = `$::cmd_lvs --noheadings -o lv_name $lvm_blockdevice 2>&1`;
		if($? == 0){
			$lv_name =~ s/^\s+|\s+$//g;
		}else{
			version_log('minor','lvm',$::backupserver_fqdn,"Source is not an LV, error: $?, $lv_name");
			$error = 1;
		}
	}
	
	## Block device found
	if($error == 0){
		if($lvm_blockdevice && $lv_name){
			#version_log('normal','lvm',$::backupserver_fqdn,"LVM Logical volume found.\nLV Block Device: $lvm_blockdevice\nLV Name: $lv_name");
		}else{
			version_log('minor','lvm',$::backupserver_fqdn,"Internal error...");
			$error = 1;
		}
	}
	
	## Check and remove snapshots
	if($error == 0){
		$result = `$::cmd_lvdisplay \"${lvm_blockdevice}_sbackup_${p_job}_snap\" 2>&1`;
		if($? == 0){
			## Snapshot exists
			## Check if snapshot is mounted
			system('mountpoint -q "/mnt/sbackup_'.${p_job}.'_snap" 2>&1');
			if($? == 0){
				## umount snapshot
				$result = `$::cmd_umount \"/mnt/sbackup_${p_job}_snap\" 2>&1`;
				if($? == 0){
					## Delete mnt directory
      		if(-d "/mnt/sbackup_${p_job}_snap"){
      			system("rmdir \"/mnt/sbackup_${p_job}_snap\"");
      			if($? != 0){
      				version_log('minor','lvm',$::backupserver_fqdn,"Failed to remove mnt directory \"/mnt/sbackup_${p_job}_snap\"");
      				#$error = 1;
      			}
      		}
				}else{
					version_log('minor','lvm',$::backupserver_fqdn,"Failed to unmount snapshot.\n$result");
					$error = 1;
				}
			}
			## Remove  snapshot
			if($error == 0){
  			$result = `$::cmd_lvremove -f \"${lvm_blockdevice}_sbackup_${p_job}_snap\" 2>&1`;
  			if($? == 0){
  				version_log('normal','lvm',$::backupserver_fqdn,"Snapshot removed successfully");
  			}else{
  				version_log('minor','lvm',$::backupserver_fqdn,"Failed remove snapshot.\n$result");
  				$error = 1;
  			}
  		}
		}else{
			version_log('minor','lvm',$::backupserver_fqdn,"Snapshot not found.");
		}
	}
		
	##
	## Error
	##
	if($error != 0){
		## Check LVM fallback
		version_log('minor','lvm',$::backupserver_fqdn,"Snapshot removal failed.");
		#::job_failed("Snapshot removal failed.");
	}

	return $result;
}

1;