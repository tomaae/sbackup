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
	my $sessionlogfile = $::SESSIONLOGPATH.$p_job."_".$SB_TIMESTART.".log";

	&f_output("DEBUG","Attempting to create LVM snapshot for path: \"$source_path\"");
	append_log($sessionlogfile,"Attempting to create LVM snapshot...");
	update_history($p_job,"perf=(Snapshot) 0%","status==running,type==backup,start==".$SB_TIMESTART);
	my $error = 0;
	my $result = "";
	my $source_dir = "";
	
	## Get dir on source
	if($error == 0){
  	my $tmp = `df --output=target \"$source_path\"|tail -1 2>&1`;
  	chomp($tmp);
  	if($? == 0){
  		$source_dir = $source_path;
  		$source_dir =~ s/^$tmp//;
  	}else{
  		append_log($sessionlogfile,"Could not get source dir.");
  		$error = 1;
  	}
	}
	
	## Get block device
	my $lvm_blockdevice = "";
	if($error == 0){
  	$lvm_blockdevice = `df --output=source \"$source_path\"|tail -1 2>&1`;
  	chomp($lvm_blockdevice);
  	if($? != 0){
  		append_log($sessionlogfile,"Could not get block device.");
  		$error = 1;
  	}
	}
	
	## Check block device
	if($error == 0 && !-b $lvm_blockdevice){
		append_log($sessionlogfile,"Snapshot creation failed: $lvm_blockdevice is not a block device");
		$error = 1;
	}
	
	## Get LV name
	my $lv_name = "";
	if($error == 0){
		$lv_name = `/sbin/lvs --noheadings -o lv_name $lvm_blockdevice 2>&1`;
		if($? == 0){
			$lv_name =~ s/^\s+|\s+$//g;
		}else{
			append_log($sessionlogfile,"Source is not an LV, error: $?, $lv_name");
			$error = 1;
		}
	}
	
	## Block device found
	if($error == 0){
		if($lvm_blockdevice && $lv_name){
			append_log($sessionlogfile,"Block device $lvm_blockdevice, LV $lv_name");
		}else{
			append_log($sessionlogfile,"Internal error...");
			$error = 1;
		}
	}
	
	## Check and remove old snapshots
	if($error == 0){
		$result = `/sbin/lvdisplay \"${lvm_blockdevice}_sbackup_${p_job}_snap\" 2>&1`;
		if($? == 0){
			## Snapshot exists
			append_log($sessionlogfile,"Old snapshot found, attempting to remove...");
			## Check if snapshot is mounted
			system('mountpoint -q "/mnt/sbackup_'.${p_job}.'_snap" 2>&1');
			if($? == 0){
				## umount snapshot
				append_log($sessionlogfile,"Old snapshot is mounted, unmounting...");
				$result = `umount \"/mnt/sbackup_${p_job}_snap\" 2>&1`;
				if($? == 0){
					append_log($sessionlogfile,"Old snapshot unmounted successfully");
				}else{
					append_log($sessionlogfile,"Unmounting failed: $result");
					$error = 1;
				}
			}
			## Remove old snapshot
			if($error == 0){
				append_log($sessionlogfile,"Attempting to remove old snapshot...");
  			$result = `/sbin/lvremove -f \"${lvm_blockdevice}_sbackup_${p_job}_snap\" 2>&1`;
  			if($? == 0){
  				append_log($sessionlogfile,"Old snapshot removed successfully");
  			}else{
  				append_log($sessionlogfile,"Old snapshot removal failed: $result");
  				$error = 1;
  			}
  		}			
		}
	}
	
	## Create LVM snapshot
	if($error == 0){
		append_log($sessionlogfile,"Creating snapshot...");
		$result = `/sbin/lvcreate -l${lvm_size}%FREE -s -n \"${lv_name}_sbackup_${p_job}_snap\" ${lvm_blockdevice} 2>&1`;
		if($? == 0){
			## Snapshot created
			append_log($sessionlogfile,"Snapshot created successfully");
			if(!-d "/mnt/sbackup_${p_job}_snap"){
  			system("mkdir \"/mnt/sbackup_${p_job}_snap\"");
  			if($? != 0){
  				append_log($sessionlogfile,"Failed to create mnt directory \"/mnt/sbackup_${p_job}_snap\"");
  				$error = 1;
  			}
  		}
			if($error == 0){
  			append_log($sessionlogfile,"Mounting snapshot...");
  			$result = `mount -oro \"${lvm_blockdevice}_sbackup_${p_job}_snap\" \"/mnt/sbackup_${p_job}_snap\"`;
  			if($? == 0){
  				append_log($sessionlogfile,"Snapshot mounted successfully");
  			}else{
  				append_log($sessionlogfile,"Snapshot faield to mounted: $result");
  				$error = 1;
  			}
  		}
		}else{
			## Failed to create snapshot
			append_log($sessionlogfile,"Snapshot creation failed: $result");
			$error = 1;
		}
	}	
	
	##
	## Error
	##
	if($error != 0){
		## Check LVM fallback
		if($lvm_fallback == 0){
			append_log($sessionlogfile,"Snapshot fallback is disabled, aborting.");
			::job_failed("Snapshot creation failed.");
		}
		append_log($sessionlogfile,"Falling back to regular backup.");
	}
	
	$error = "/mnt/sbackup_${p_job}_snap".$source_dir if $error == 0;
	
	return $error;
}

##
## lvm_remove_snapshot
##
sub lvm_remove_snapshot {
	my ($p_job, $SB_TIMESTART, $source_path, $lvm_size, $lvm_fallback)=@_;
	my $sessionlogfile = $::SESSIONLOGPATH.$p_job."_".$SB_TIMESTART.".log";

	&f_output("DEBUG","Attempting to remove LVM snapshot for path: \"$source_path\"");
	append_log($sessionlogfile,"Attempting to remove LVM snapshot...");
	update_history($p_job,"perf=(Snapshot) 100%","status==running,type==backup,start==".$SB_TIMESTART);
	my $error = 0;
	my $result = "";
	
	## Get block device
	my $lvm_blockdevice = "";
	if($error == 0){
  	$lvm_blockdevice = `df --output=source \"$source_path\"|tail -1 2>&1`;
  	chomp($lvm_blockdevice);
  	if($? != 0){
  		append_log($sessionlogfile,"Could not get block device.");
  		$error = 1;
  	}
  }
	
	## Check block device
	if($error == 0 && !-b $lvm_blockdevice){
		append_log($sessionlogfile,"Snapshot removal failed: $lvm_blockdevice is not a block device");
		$error = 1;
	}
	
	## Get LV name
	my $lv_name = "";
	if($error == 0){
		$lv_name = `/sbin/lvs --noheadings -o lv_name $lvm_blockdevice 2>&1`;
		if($? == 0){
			$lv_name =~ s/^\s+|\s+$//g;
		}else{
			append_log($sessionlogfile,"Source is not an LV");
			$error = 1;
		}
	}
	
	## Block device found
	if($error == 0){
		if($lvm_blockdevice && $lv_name){
			append_log($sessionlogfile,"Block device $lvm_blockdevice, LV $lv_name");
		}else{
			append_log($sessionlogfile,"Internal error...");
			$error = 1;
		}
	}
	
	## Check and remove snapshots
	if($error == 0){
		$result = `/sbin/lvdisplay \"${lvm_blockdevice}_sbackup_${p_job}_snap\" 2>&1`;
		if($? == 0){
			## Snapshot exists
			append_log($sessionlogfile,"Snapshot found, attempting to remove...");
			## Check if snapshot is mounted
			system('mountpoint -q "/mnt/sbackup_'.${p_job}.'_snap" 2>&1');
			if($? == 0){
				## umount snapshot
				append_log($sessionlogfile,"Unmounting snapshot...");
				$result = `umount \"/mnt/sbackup_${p_job}_snap\" 2>&1`;
				if($? == 0){
					append_log($sessionlogfile,"Snapshot unmounted successfully");
					## Delete mnt directory
      		if(-d "/mnt/sbackup_${p_job}_snap"){
      			system("rmdir \"/mnt/sbackup_${p_job}_snap\"");
      			if($? != 0){
      				append_log($sessionlogfile,"Failed to remove mnt directory \"/mnt/sbackup_${p_job}_snap\"");
      				#$error = 1;
      			}
      		}
				}else{
					append_log($sessionlogfile,"Unmounting failed: $result");
					$error = 1;
				}
			}
			## Remove  snapshot
			if($error == 0){
				append_log($sessionlogfile,"Attempting to remove snapshot...");
  			$result = `/sbin/lvremove -f \"${lvm_blockdevice}_sbackup_${p_job}_snap\" 2>&1`;
  			if($? == 0){
  				append_log($sessionlogfile,"Snapshot removed successfully");
  			}else{
  				append_log($sessionlogfile,"Snapshot removal failed: $result");
  				$error = 1;
  			}
  		}
		}else{
			append_log($sessionlogfile,"Snapshot not found");
		}
	}
		
	##
	## Error
	##
	if($error != 0){
		## Check LVM fallback
		append_log($sessionlogfile,"Snapshot removal failed.");
		#::job_failed("Snapshot removal failed.");
	}

	return $result;
}

1;