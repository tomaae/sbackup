package rsync;

###########################################################################################
#
#                                         sbackup
#                                    rsync integration
#
###########################################################################################

use strict;
use warnings;
use init;
use logger;
use POSIX qw(strftime mktime ceil);

use Exporter qw(import);
our @ISA = qw(Exporter);
our @EXPORT = qw(rsync_backup);

##
## rsync_backup
##
sub rsync_backup {
	my ($p_job, $SB_TIMESTART, $source_path, $target_path)=@_;
	
	my @returncodes;

  ##
  ## Check backup history
  ##
  my $INCR = "";
  if(-f $::VARPATH.'history_'.$p_job){
  	##Get backup status from history
  	&f_output("DEBUG","History log found, checking history.");
  	my $LAST_FAILED_STAMP    = 0;
  	my $LAST_COMPLETED_STAMP = 0;
    my @output = &get_history($p_job,'status,start','type==backup');
    for my $tmp(@{$output[2]}){
    	if($$tmp{'start'} eq $SB_TIMESTART){
    		&f_output("DEBUG","Skipping current backup in history file.");
    		next;
    	}
    	if($$tmp{'start'} ne "" && $$tmp{'start'} > 100 && -d $target_path.$::slash."data_".$$tmp{'start'}){
    		if($$tmp{'status'} =~ /^\d+$/ && ($$tmp{'status'} eq "1" || $$tmp{'status'} eq "2" || $$tmp{'status'} eq "3")){
    			$LAST_COMPLETED_STAMP = $$tmp{'start'};
    		}else{
    			$LAST_FAILED_STAMP = $$tmp{'start'};
    		}
    	}else{
    		&f_output("DEBUG","Data not found for job $$tmp{'start'}");
    	}
    }
    &f_output("DEBUG","Last failed version: ".$LAST_FAILED_STAMP) if $LAST_FAILED_STAMP;
    &f_output("DEBUG","Last completed version: ".$LAST_COMPLETED_STAMP) if $LAST_COMPLETED_STAMP;
    
    if($LAST_COMPLETED_STAMP || $LAST_FAILED_STAMP){
    	##Check for backup to restart
    	if($LAST_FAILED_STAMP > $LAST_COMPLETED_STAMP){
    		&f_output("DEBUG","Last version is failed, cleaning up and restarting.");
  			version_log('normal','backup',$::backupserver_fqdn,"Restarting backup job from version ".strftime("%G/%m/%d-%H%M%S", localtime($LAST_FAILED_STAMP)));
  			if(!$main::SIMULATEMODE){
    			system("$::cmd_mv ".$target_path.$::slash."data_".$LAST_FAILED_STAMP." ".$target_path.$::slash."data_".$SB_TIMESTART);
    			::job_failed("Failed to resume backup job.") if $? != 0;
  			}
    	}
    	
    	##Check for last completed backup
    	if($LAST_COMPLETED_STAMP){
    		&f_output("DEBUG","Last completed backup found, incremental enabled.");
  			$INCR=" --link-dest=\"".$target_path.$::slash."data_".$LAST_COMPLETED_STAMP.$::slash."\"";
    	}
  	}
  }else{
  	&f_output("DEBUG","History log not found, initial backup.");
  }

  my $SB_ECODE = "";
  my $JOB_SIZE = "";
  my $JOB_PERF = "";
  
  my $total_size           = 0;
  my $copied_size          = 0;
  my $copied_last_size     = 0;
  my $progress_percent     = 0;
  my $progress_percent_old = 0;
  
  my $line_flags    = "";
  my $line_entry    = "";
  my $line_size     = "";
  my $line_modified = "";
  my $line_perm     = "";
  my $line_owner    = "";
  my $line_group    = "";
  
  my @os_ownerlist = ();
  my @os_grouplist = ();
    
  &f_output("DEBUG","Getting change list for backup.");
  version_log('normal','rsync',$::backupserver_fqdn,"Traversing source filesystem...");
  my $rsync_params = " --stats -aEAXvii --out-format='%i|%n|%l|%M|%B|%U|%G' --delete ".$INCR." \"".$source_path.$::slash."\" \"".$target_path.$::slash."data_".$SB_TIMESTART.$::slash."\"";
  open(my $cmd_out,"-|","$::cmd_rsync --dry-run $rsync_params 2>&1") || ::job_failed("Failed to start rsync.");
  my @val;
  while (my $line = <$cmd_out>){
  	chomp($line);
  	if($line =~ /\|/){
  		@val = split(/\|/,$line);
  		$line_flags    = $val[0];
  		$line_size     = $val[2];
  		
  		next if $line_entry eq './'; ## Skip root directory
  		
  		if($line_flags =~ /^\>f/){
  			$total_size += $line_size if $line_size > 0;
  		}
  	}else{
  		if($line =~ /^Total file size: ([0-9,\.]+) bytes/){
  			$JOB_SIZE = $1;
  			$JOB_SIZE =~ s/,//g;
  		}
  	}
  }
  close($cmd_out);
  update_history($p_job,"size=".$JOB_SIZE.",perf=0%","status==0,type==backup,start==".$SB_TIMESTART);

  my $total_size_human = $total_size." B";
  $total_size_human = ceil($total_size / 1024)." KiB" if $total_size > (100 * 1024);
  $total_size_human = ceil($total_size / 1024 / 1024)." MiB" if $total_size > (9 * 1024 * 1024);
  $total_size_human = ceil($total_size / 1024 / 1024 / 1024)." GiB" if $total_size > (9 * 1024 * 1024 * 1024);
  version_log('normal','rsync',$::backupserver_fqdn,"Data to transfer: $total_size_human");

  $total_size = 1 if $total_size == 0; ## Never divide by 0;

  &f_output("DEBUG","Starting backup.");
  &f_output("DEBUG3","Execute: \"$::cmd_rsync $rsync_params\"");
  
  my $aborting = 0;
  my $data_changed = 0;
  my $rsync_summary = "";
  
  my $catalogfile_dirs   = $CATALOGPATH.$p_job."_".$SB_TIMESTART.".dirs";
  my $catalogfile_files  = $CATALOGPATH.$p_job."_".$SB_TIMESTART.".files";
  my $catalogfile_owners = $CATALOGPATH.$p_job."_".$SB_TIMESTART.".owners";
  my $catalogfile_groups = $CATALOGPATH.$p_job."_".$SB_TIMESTART.".groups";
  
  my @pid_output = &get_runfile($p_job,'status,type,pid');
  $aborting = 1 if $pid_output[0] && $pid_output[2][0]{'pid'}  =~ /^\d+$/ && $pid_output[2][0]{'status'} eq '6';
  if(!$aborting){
  	my $cat_type = "";
  	my $cat_entry = "";
  	my $cat_dirid = 0;
  	my @cat_dirs = ();
  	@{$cat_dirs[0]} = ();
  	
  	if(!$main::SIMULATEMODE){
  		open cat_file,">>$catalogfile_files" or ::job_failed("Insufficient access rights.");
  		flock cat_file,2;
  		truncate cat_file,0;
  	}
  	
    my $rsync_simulate = "";
    $rsync_simulate = ' --dry-run ' if $main::SIMULATEMODE;
    my $rpid = open(my $cmd_out,"-|","$::cmd_rsync $rsync_simulate $rsync_params 2>&1") || ::job_failed("Failed to start rsync.");
    update_runfile($p_job,"rpid=".$rpid) if $rpid && $rpid > 0;
    while (my $line = <$cmd_out>){
    	if($copied_last_size > 0){
    		$copied_size += $copied_last_size;
    		$copied_size = $total_size if $copied_size > $total_size;
    		
    		$progress_percent = ($copied_size/$total_size)*100;
    		$progress_percent =~ /(\d+)\.?\d?\d?/;
    		$progress_percent = $1;
    		
    		update_history($p_job,"perf=".$progress_percent."%","status==0,type==backup,start==".$SB_TIMESTART) if $progress_percent ne $progress_percent_old;
      	$progress_percent_old = $progress_percent;
      	$copied_last_size = 0;
    	}
    	chomp($line);
    	if($line =~ /\|/){
    		@val = split(/\|/,$line);
    		$line_flags    = $val[0];
    		$line_entry    = $val[1];
    		$line_size     = $val[2];
    		$line_modified = $val[3];
    		$line_perm     = $val[4];
    		$line_owner    = $val[5];
    		$line_group    = $val[6];
    		
    		## Skip root directory
    		next if $line_entry eq './';
    		
    		## Convert time to epoch
    		if($line_modified =~ /^(\d{4})\/(\d{2})\/(\d{2})\-(\d{2}):(\d{2}):(\d{2})$/){
    			$line_modified = mktime($6,$5,$4,$3,$2 - 1,$1 - 1900);
    		}else{
    			version_log('warning','rsync',$::backupserver_fqdn,"Cannot parse to catalog:\nTime: \"$cat_entry\"");
    		}
    		
    		##
    		## Parsing for catalog
    		##
    		if($line_flags =~ /^[^*](f|d|L|D|S)/){#f for a file, a d for a directory, an L for a symlink, a D for a device, and a S for a special file
    			$cat_type = $1;
    			$cat_entry = $line_entry;
    			
    			## Parse permission bits
    			if($line_perm ne ""){
    				$line_perm =~ s/\-/0/g;
    				$line_perm =~ s/r|w|x/1/g;
    				if($line_perm =~ /^(\d{3})(\d{3})(\d{3})$/){
    					$line_perm = oct('0b'.$1).oct('0b'.$2).oct('0b'.$3);
    				}else{
    					$line_perm = "";
    				}
    			}

    			$os_ownerlist[$line_owner] = "" if $line_owner =~ /^\d+$/;
    			$os_grouplist[$line_group] = "" if $line_group =~ /^\d+$/;
    			
    			## Parse directories
    			if($cat_type eq "d"){
    				version_log('warning','rsync',$::backupserver_fqdn,"Cannot parse to catalog:\nNot a directory \"$cat_entry\"") if $cat_entry !~ s/\/$//;
    				
    				## Find parent dirid
    				$cat_dirid = 0;
    				my @cat_split = split(/\//,$cat_entry);
    				for my $cat_tmp(@cat_split){
    					if(defined $cat_dirs[$cat_dirid]){
    						## Check if present under current dirid
    						my $cat_cid = 0;
    						my $i = -1;
    						for(@{$cat_dirs[$cat_dirid]}){
    							$i++;
    							next if not defined $cat_dirs[$cat_dirid][$i];
    							if($cat_dirs[$cat_dirid][$i][1] eq $cat_tmp){
    								$cat_cid = $cat_dirs[$cat_dirid][$i][0];
    								last;
    							}
    						}
    						## Not present
    						if($cat_cid == 0){
    							$cat_cid = scalar(@cat_dirs);
    							my @cat_dirs_tmp = ($cat_cid, $cat_tmp, $line_perm, $line_owner, $line_group);
    							push @{$cat_dirs[$cat_dirid]},\@cat_dirs_tmp;
    							@{$cat_dirs[$cat_cid]} = ();
    						}
    						$cat_dirid = $cat_cid;
    					}
    				}
    			}else{
    				## Parse files
    				version_log('warning','rsync',$::backupserver_fqdn,"Cannot parse to catalog:\nNot a file: \"$cat_entry\"") if $cat_entry !~ s/\/([^\/]+)$// && $cat_entry !~ s/^([^\/]+)$//;
    				my $cat_file = $1;
    				## Find parent dirid
    				$cat_dirid = 0;
    				my @cat_split = split(/\//,$cat_entry);
    				for my $cat_tmp(@cat_split){
    					if(defined $cat_dirs[$cat_dirid]){
    						## Check if present under current dirid
    						my $i = -1;
    						for(@{$cat_dirs[$cat_dirid]}){
    							$i++;
    							next if ! defined $cat_dirs[$cat_dirid][$i];
    							if($cat_dirs[$cat_dirid][$i][1] eq $cat_tmp){
    								$cat_dirid = $cat_dirs[$cat_dirid][$i][0];
    								last;
    							}
    						}
    					}
    				}
    				print cat_file "$cat_dirid|$cat_file|$line_size|$line_modified|$line_perm|$line_owner|$line_group\n" if !$main::SIMULATEMODE;
    			}
    		}
    		
    		##
    		## Parsing for version log
    		##
    		if($line_flags =~ /^\>f/){ ## New file
    			
    			$copied_last_size = $line_size if $line_size > 0;
      		if($line_flags =~ /^\>f\+/){
      			append_log($::sessionlogfile,'+'.$line_entry);
      		}else{
      			append_log($::sessionlogfile,'*'.$line_entry);
      		}
      		$data_changed = 1;
      	}elsif($line_flags =~ /^\*deleting/){ ## Deleted
      		append_log($::sessionlogfile,'-'.$line_entry);
      		$data_changed = 1;
      	}elsif($line_flags =~ /^cd\+/){ ## New directory
      		append_log($::sessionlogfile,'+'.$line_entry);
      		$data_changed = 1;
      	}elsif($line_flags =~ /\+/){ ## New other
      		append_log($::sessionlogfile,'+'.$line_entry);
      		$data_changed = 1;
      	}elsif($line_flags =~ /^c/){ ## Local change other
      		next;
      	}elsif($line_flags =~ /^h/){ ## Hardlink 
      		next;
      	}elsif($line_flags =~ /^\./){ ## Not modified
      		next;    		
      	}else{
      		version_log('warning','rsync',$::backupserver_fqdn,$line);
      	}
    	}else{
    		if($line =~ /sending incremental file list/){
    			version_log('normal','rsync',$::backupserver_fqdn,"Starting data transfer...");
    		}elsif($line =~ /^Number of files: / || $rsync_summary ne ""){
    			$rsync_summary .= $line."\n";
    			if($line =~ /^total size is/){
    				append_log($::sessionlogfile,"\n") if $data_changed;
    				version_log('normal','rsync',$::backupserver_fqdn,"Backup job summary:\n\n$rsync_summary");
    				$rsync_summary = "";
    			}
    		}elsif($line =~ /^\s*$/){
    			next;
    		}else{
    			my $severity = "warning";
    			$severity = "major" if $line =~ /^rsync.*error/;
      		version_log($severity,'rsync',$::backupserver_fqdn,$line);
      	}
    	}
    }
    close($cmd_out);
    
    if(!$main::SIMULATEMODE){
			flock cat_file,8;
			close cat_file;
    }
    
    if($rsync_summary ne ""){
    	append_log($::sessionlogfile,"\n") if $data_changed;
    	version_log('normal','rsync',$::backupserver_fqdn,"Backup job summary:\n\n$rsync_summary");
    	$rsync_summary = "";
    }
    
    ## Save dir catalog
     if(!$main::SIMULATEMODE){
  		open log_file,">>$catalogfile_dirs" or ::job_failed("Insufficient access rights.");
  		flock log_file,2;
  		truncate log_file,0;
  	}
    my $i = -1;
    for(@cat_dirs){
    	$i++;
    	next if scalar @{$cat_dirs[$i]} == 0;
    	my $e = -1;
    	for(@{$cat_dirs[$i]}){
    		$e++;
    		print log_file "$i|$cat_dirs[$i][$e][0]|$cat_dirs[$i][$e][1]|$cat_dirs[$i][$e][2]|$cat_dirs[$i][$e][3]|$cat_dirs[$i][$e][4]\n" if !$main::SIMULATEMODE;
    	}
    }
    if(!$main::SIMULATEMODE){
			flock log_file,8;
			close log_file;
    }
    
    ## Save owner list
    if(!$main::SIMULATEMODE){
  		open log_file,">>$catalogfile_owners" or ::job_failed("Insufficient access rights.");
  		flock log_file,2;
  		truncate log_file,0;
  	}
    for my $line(read_log($::OS_USERS)){
    	chomp($line);
    	my @val = split(/\:/,$line);
    	print log_file "$val[2]|$val[0]\n" if defined $os_ownerlist[$val[2]] && !$main::SIMULATEMODE;
    }
    if(!$main::SIMULATEMODE){
			flock log_file,8;
			close log_file;
    }
    
    ## Save group list
    if(!$main::SIMULATEMODE){
  		open log_file,">>$catalogfile_groups" or ::job_failed("Insufficient access rights.");
  		flock log_file,2;
  		truncate log_file,0;
  	}
    for my $line(read_log($::OS_GROUPS)){
    	chomp($line);
    	my @val = split(/\:/,$line);
    	print log_file "$val[2]|$val[0]\n" if defined $os_grouplist[$val[2]] && !$main::SIMULATEMODE;
    }
    if(!$main::SIMULATEMODE){
			flock log_file,8;
			close log_file;
    }
    
    
    $SB_ECODE = $?;
    version_log('normal','rsync',$::backupserver_fqdn,"Nothing backed up, no changed data found.") if $SB_ECODE eq "0" && !$data_changed;
  }

  ## Update backup size and performance
  if($SB_ECODE eq "0"){
    for(read_log($::sessionlogfile)){
    	chomp;
    	if(/^Total file size: ([0-9,\.]+) bytes/){
    		$JOB_SIZE = $1;
    		$JOB_SIZE =~ s/,//g;
    	}
    	if(/ ([0-9,]+).\d\d bytes\/sec$/){
    		$JOB_PERF = $1;
    		$JOB_PERF =~ s/,//g;
    	}
    }
  }

  ## Check abort status
  if($SB_ECODE ne "" && $SB_ECODE != 0){
  	if(!$aborting){
  		my @pid_output = &get_runfile($p_job,'status,type,pid');
  		$aborting = 1 if $pid_output[0] && $pid_output[2][0]{'pid'}  =~ /^\d+$/ && $pid_output[2][0]{'status'} eq '6';
  	}
  	if($aborting){
  		$::SB_ERRORLEVEL = "6";
  		version_log('minor','rsync',$::backupserver_fqdn,"Job aborted by user.");
  	}
  }
  $::SB_ERRORLEVEL = 5 if $SB_ECODE ne "0" && $::SB_ERRORLEVEL < 5;
  
  $returncodes[0] = 1;
  $returncodes[1]{'JOB_SIZE'} = $JOB_SIZE;
  $returncodes[1]{'JOB_PERF'} = $JOB_PERF;
  
  return @returncodes;
}

1;