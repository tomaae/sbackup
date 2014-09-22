package sbackup_init;

###########################################################################################
#
#                                         sbackup
#                                          init
#
###########################################################################################

BEGIN {
	$MODULE_NAME = "sbackup_init";
	push @main::DEBUGHEADERS,"DEBUGGER: module: $MODULE_NAME";

	use Exporter   ();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

	@ISA         = qw(Exporter);
	@EXPORT      = qw(&f_output &append_log &write_log &read_log &f_epoch2human &f_time2min &f_min2time &f_time2block &f_block2time &round &f_cstr &f_getenv &f_getjobs);
	%EXPORT_TAGS = ( );

	# exported package globals, as well as any optionally exported functions
	@EXPORT_OK   = qw();
}
our @EXPORT_OK;

##
##OUTPUT HANDLER
##
sub f_output {
	my ($msg_type,$err_msg,$additionalcode)=@_;
	my ($sec,$min,$hour,$mday,$mon,$year, $wday,$yday,$isdst) = localtime;
	my $debug_type;
	my $debug_show = 0;
	my $reportdate = substr(($hour + 100),1,2).':'.substr(($min + 100),1,2).':'.substr(($sec + 100),1,2);
	if($msg_type eq "ERROR"){
		print "\n$err_msg\n";
		if($additionalcode){exit $additionalcode;}
	}
	if($main::DEBUGMODE){
		if($msg_type eq "DEBUG"){
			$debug_type = "MSG";
			$debug_show = 1;
		}
		if($msg_type eq "DEBUG1"){
			$debug_type = "ERR";
			$debug_show = 1;
		}
		if($msg_type eq "DEBUG2" && $main::p_debug >= 2){
			$debug_type = "DET";
			$debug_show = 1;
		}
		if($msg_type eq "DEBUG3" && $main::p_debug >= 3){
			$debug_type = "DET3";
			$debug_show = 1;
		}
		if($msg_type eq "DEBUG4" && $main::p_debug >= 4){
			$debug_type = "DET4";
			$debug_show = 1;
		}
		if($msg_type eq "DEBUG5" && $main::p_debug >= 5){
			$debug_type = "DET5";
			$debug_show = 1;
		}

		if($debug_show){
			print "=DEBUG-$debug_type-$reportdate=>$err_msg\n";
		}
	}
	if($msg_type eq "SCREEN"){
		print "$err_msg";
	}
	if($msg_type eq "HTML" &&($main::sv_html)){
		printf main::htmlfile "$err_msg\n";
	}
}

##
##APPEND LOG
##
sub append_log{
	my ($logfile,$logentry)=@_;
  &f_output("DEBUG","Added to log file \"$logfile\": $logentry");
	return if $main::SIMULATEMODE;
	open log_file,">>$logfile";
	flock log_file,2;
	seek log_file,0,2;
  print log_file "$logentry\n";
  flock log_file,8;
  close log_file;
}

sub write_log{
	my ($logfile,$logentry)=@_;
  &f_output("DEBUG","Overwrite to log file \"$logfile\": $logentry");
	return if $main::SIMULATEMODE;
	open log_file,">>$logfile";
	flock log_file,2;
	truncate log_file,0;
  print log_file "$logentry\n";
  flock log_file,8;
  close log_file;
}

sub read_log{
	my ($logfile)=@_;
  &f_output("DEBUG","Reading log file \"$logfile\"");
	open log_file,"<$logfile";
	flock log_file,1;
  @tmp = <log_file>;
  flock log_file,8;
  close log_file;
  return @tmp;
}

##
##Time convert
##
sub f_epoch2human {
	my ($epoch)=@_;
	return "Unknown" if !$epoch;
	my ($analyze_sec,$analyze_min,$analyze_hour,$analyze_mday,$analyze_mon,$analyze_year,$dummy,$dummy2,$dummy3) = localtime($epoch);
	$analyze_hour = "0".$analyze_hour if length($analyze_hour)==1;
	$analyze_min = "0".$analyze_min if length($analyze_min)==1;
	$analyze_sec = "0".$analyze_sec if length($analyze_sec)==1;
	return substr(($analyze_mday + 100),1,2)."/".substr(($analyze_mon + 101),1,2)."/".substr(($analyze_year),1,2)." $analyze_hour:$analyze_min:$analyze_sec";
}

sub f_time2min {
	my ($timestr)=@_;
	my @durationval = split(/\:/,$timestr);
	return ($durationval[0] * 60) + $durationval[1];
}

sub f_min2time {
	my ($timestr)=@_;
	my $hours = int($timestr/60);
	my $minutes = $timestr - ($hours * 60);
	if(length($hours) == 1){$hours = "0".$hours;}
	if(length($minutes) == 1){$minutes = "0".$minutes;}
	return "$hours\:$minutes";
}

sub f_time2block {
	my ($timestr)=@_;
	my @durationval = split(/\:/,$timestr);
	$timeframe_hour = $durationval[0];
	$timeframe_min = $durationval[1];
	if($timeframe_min > 45){$timeframe_min = 60;}elsif($timeframe_min > 30){$timeframe_min = 45;}elsif($timeframe_min > 15){$timeframe_min = 30;}elsif($timeframe_min > 0){$timeframe_min = 15;}
	if($timeframe_min == 60){$timeframe_hour++;$timeframe_min = 0;}
	if($timeframe_hour == 24){$timeframe_hour = 0;}
	if(length($timeframe_hour) == 1){$timeframe_hour = "0".$timeframe_hour;}
	if(length($timeframe_min) == 1){$timeframe_min = "0".$timeframe_min;}
	$duration = ($timeframe_hour * 60) + $timeframe_min;
	$restarttimeid = (($duration/15)+1);
	return $restarttimeid;
}

sub f_block2time {
	my ($timestr)=@_;
	$timestr *= 15;
	return &f_min2time($timestr);
}

sub round {
	my($number) = shift;
	return int($number + .2);
}

##
##STRING TRANSLATION
##
sub f_cstr { #TRANSLATE
	my ($type,$tmp)=@_;
	if($type eq "E"){
		$tmp =~ s/\:/__COL__/g;
		$tmp =~ s/\+/__PLU__/g;
		$tmp =~ s/\\/__BSL__/g;
		$tmp =~ s/\//__SLA__/g;
		$tmp =~ s/\-/__HYP__/g;
		$tmp =~ s/\%/__PRC__/g;
		$tmp =~ s/\./__DOT__/g;
		$tmp =~ s/\~/__TIL__/g;
		$tmp =~ s/\'/__APO__/g;
		$tmp =~ s/\"/__QUO__/g;
	}else{
		$tmp =~ s/__COL__/\:/g;
		$tmp =~ s/__PLU__/\+/g;
		$tmp =~ s/__BSL__/\\/g;
		$tmp =~ s/__SLA__/\//g;
		$tmp =~ s/__HYP__/\-/g;
		$tmp =~ s/__PRC__/\%/g;
		$tmp =~ s/__DOT__/\./g;
		$tmp =~ s/__TIL__/\~/g;
		$tmp =~ s/__APO__/\'/g;
		$tmp =~ s/__QUO__/\"/g;
	}
	return $tmp;
}

sub f_getenv{
	&f_output("DEBUG","Setting required parameters.");
	$main::s_slash="/";
	
	$main::BINPATH        = "/usr/share/sbackup/";
	$main::MODULESPATH    = "/usr/share/sbackup/modules/";
	$main::CONFIGPATH     = "/etc/sbackup/";
	$main::JOBCONFIGPATH  = "/etc/sbackup/jobs/";
	$main::HISTORYPATH    = "/var/log/sbackup/";
	$main::SESSIONLOGPATH = "/var/log/sbackup/sessionlogs/";
	$main::RUNFILEPATH    = "/var/log/sbackup/run/";

	$main::s_browsedir    = "ls -l";
	$main::cmd_rm         = "rm -r";
	$main::cmd_sleep      = "sleep";
	$main::cmd_cp         = "cp";
	$main::cmd_mv         = "mv";
	$main::cmd_mkdir      = "mkdir -p";
	$main::cmd_chmod      = "chmod";
	$main::cmd_rsync      = "rsync";
	
	&f_output("DEBUG","Required parameters set.");
}

sub f_getjobs{
	&f_output("DEBUG","Getting job configuration configuration.");
	%main::JOBID = ();
	%main::JOBNAME = ();
	my @val;
  if( -d $main::JOBCONFIGPATH ){
    for (`$main::s_browsedir $main::JOBCONFIGPATH`){
      chomp;next if /^$/;next if /^0$/;next if /^d/;next if /^total/;next if /\<DIR\>/;next if /File\(s\)/;next if /\Dir\(s\)/;next if /Volume in drive/;next if /Volume Serial/;next if /Directory of/;
      @val=split(/ /);
      if( -e $main::JOBCONFIGPATH.$main::s_slash.$val[-1] ){
      	&f_output("DEBUG3","Found job specification \"".$val[-1]."\".");
      	$main::JOBID{&f_cstr("E",$val[-1])}{'file'} = $main::JOBCONFIGPATH.$main::s_slash.$val[-1];
    	}
    }
  }else{
  	&f_output("ERROR","Job directory missing.",9);
  }
  
	my %known_variables = (
    "uuid"=>1,
    "enable"=>1,
    "name"=>1,
    "job_type"=>1,
    "backup_type"=>1,
    "source_sharedfolder_uuid"=>0,
    "backup_source_mnt"=>0,
    "backup_source"=>0,
    "target_sharedfolder_uuid"=>0,
    "backup_target_mnt"=>0,
    "backup_target"=>0,
    "schedule_enable"=>0,
    "schedule_mon"=>0,
    "schedule_tue"=>0,
    "schedule_wed"=>0,
    "schedule_thu"=>0,
    "schedule_fri"=>0,
    "schedule_sat"=>0,
    "schedule_sun"=>0,
    "schedule_hour"=>0,
    "schedule_minute"=>0,
    "lvmsnap_enable"=>0,
    "lvmsnap_size"=>0,
    "lvmsnap_fallback"=>0,
    "queue"=>0,
    "autorestart"=>0,
    "report"=>0,
    "post_purge"=>0,
    "protect_days_job"=>1,
    "post_job"=>0,
    "purge_job_uuid"=>0,
    "verify_job_uuid"=>0
  );
  
	my @variable_error  = ();
	my @value_error     = ();
	my @found_variable  = ();
	my @found_value     = ();
	my $return_error    = 0;
  
  for my $jobid_tmp(keys %main::JOBID){
  	
  	open cfgfile,"<".$main::JOBID{$jobid_tmp}{'file'} or &f_output("ERROR","Cannot open \"".$main::JOBID{$jobid_tmp}{'file'}."\".",9);
  	while (<cfgfile>){
  		chomp;
  		if(!$main::cfgversion && /^# revision /){
  			s/^\s+|\s+$//g;
  			@val = split(/ /);
  			$main::cfgversion = $val[2];
  		}
  		s/#.*//; ##Remove everything after hash
  		s/^\s+|\s+$//g; ##Delete leading and trailing spaces
  		next if /^$/;
  		my @split_line = split /\s*=\s*/,$_;
  		$split_line[0] = lc $split_line[0]; ##Convert variable to lowercase
  		$split_line[1] =~ s/\"//g; ##Remove quotes
  		if (!exists $known_variables{$split_line[0]}){
  			push @variable_error,"Variable \"$split_line[0]\" is not known. Line $."; # Not in list of known variables
  			$return_error=1;
  		}elsif ($known_variables{$split_line[0]} == 1 && $split_line[1] eq ""){
  			push @value_error,"Value is not assigned to mandatory variable \"$split_line[0]\". Line $."; # Mandatory variables must be assigned
  			$return_error=1;
  		}else{
  			push @found_variable,$split_line[0];
  			push @found_value,$split_line[1];
  		}
  	}
  	close cfgfile;
  	##CHECK IF ALL MANDATORY VARIABLES ARE CONFIGURED IN CFG FILE
  	for $tmp(keys %known_variables){
  		next if ($known_variables{$tmp} != 1);
  		my $mandatory_variable = $tmp; 
  		my $mandatory_variable_set = 0;
  		for (my $count=0;$count<@found_variable;$count++){
  			if ($mandatory_variable eq $found_variable[$count]){
  				$mandatory_variable_set = 1;
  				last;
  			}
  		}
  		if ($mandatory_variable_set == 0){
  			push @variable_error,"Not all mandatory variables configured in configuration file - \"$mandatory_variable\".";
  			$return_error = 1;
  		}
  	}
  	
  	for (my $count=0;$count < @found_variable;$count++){
      if($found_variable[$count] eq 'uuid'){$main::JOBID{$jobid_tmp}{'uuid'} = $found_value[$count];}
      if($found_variable[$count] eq 'enable'){$main::JOBID{$jobid_tmp}{'enable'} = $found_value[$count];}
      if($found_variable[$count] eq 'name'){$main::JOBID{$jobid_tmp}{'name'} = $found_value[$count];}
      if($found_variable[$count] eq 'job_type'){$main::JOBID{$jobid_tmp}{'job_type'} = $found_value[$count];}
      if($found_variable[$count] eq 'backup_type'){$main::JOBID{$jobid_tmp}{'backup_type'} = $found_value[$count];}
      if($found_variable[$count] eq 'source_sharedfolder_uuid'){$main::JOBID{$jobid_tmp}{'source_sharedfolder_uuid'} = $found_value[$count];}
      if($found_variable[$count] eq 'backup_source_mnt'){$main::JOBID{$jobid_tmp}{'backup_source_mnt'} = $found_value[$count];}
      if($found_variable[$count] eq 'backup_source'){$main::JOBID{$jobid_tmp}{'backup_source'} = $found_value[$count];}
      if($found_variable[$count] eq 'target_sharedfolder_uuid'){$main::JOBID{$jobid_tmp}{'target_sharedfolder_uuid'} = $found_value[$count];}
      if($found_variable[$count] eq 'backup_target_mnt'){$main::JOBID{$jobid_tmp}{'backup_target_mnt'} = $found_value[$count];}
      if($found_variable[$count] eq 'backup_target'){$main::JOBID{$jobid_tmp}{'backup_target'} = $found_value[$count];}
      if($found_variable[$count] eq 'schedule_enable'){$main::JOBID{$jobid_tmp}{'schedule_enable'} = $found_value[$count];}
      if($found_variable[$count] eq 'schedule_mon'){$main::JOBID{$jobid_tmp}{'schedule_mon'} = $found_value[$count];}
      if($found_variable[$count] eq 'schedule_tue'){$main::JOBID{$jobid_tmp}{'schedule_tue'} = $found_value[$count];}
      if($found_variable[$count] eq 'schedule_wed'){$main::JOBID{$jobid_tmp}{'schedule_wed'} = $found_value[$count];}
      if($found_variable[$count] eq 'schedule_thu'){$main::JOBID{$jobid_tmp}{'schedule_thu'} = $found_value[$count];}
      if($found_variable[$count] eq 'schedule_fri'){$main::JOBID{$jobid_tmp}{'schedule_fri'} = $found_value[$count];}
      if($found_variable[$count] eq 'schedule_sat'){$main::JOBID{$jobid_tmp}{'schedule_sat'} = $found_value[$count];}
      if($found_variable[$count] eq 'schedule_sun'){$main::JOBID{$jobid_tmp}{'schedule_sun'} = $found_value[$count];}
      if($found_variable[$count] eq 'schedule_hour'){$main::JOBID{$jobid_tmp}{'schedule_hour'} = $found_value[$count];}
      if($found_variable[$count] eq 'schedule_minute'){$main::JOBID{$jobid_tmp}{'schedule_minute'} = $found_value[$count];}
      if($found_variable[$count] eq 'lvmsnap_enable'){$main::JOBID{$jobid_tmp}{'lvmsnap_enable'} = $found_value[$count];}
      if($found_variable[$count] eq 'lvmsnap_size'){$main::JOBID{$jobid_tmp}{'lvmsnap_size'} = $found_value[$count];}
      if($found_variable[$count] eq 'lvmsnap_fallback'){$main::JOBID{$jobid_tmp}{'lvmsnap_fallback'} = $found_value[$count];}
      if($found_variable[$count] eq 'queue'){$main::JOBID{$jobid_tmp}{'queue'} = $found_value[$count];}
      if($found_variable[$count] eq 'autorestart'){$main::JOBID{$jobid_tmp}{'autorestart'} = $found_value[$count];}
      if($found_variable[$count] eq 'report'){$main::JOBID{$jobid_tmp}{'report'} = $found_value[$count];}
      if($found_variable[$count] eq 'post_purge'){$main::JOBID{$jobid_tmp}{'post_purge'} = $found_value[$count];}
      if($found_variable[$count] eq 'protect_days_job'){$main::JOBID{$jobid_tmp}{'protect_days_job'} = $found_value[$count];}
      if($found_variable[$count] eq 'post_job'){$main::JOBID{$jobid_tmp}{'post_job'} = $found_value[$count];}
      if($found_variable[$count] eq 'purge_job_uuid'){$main::JOBID{$jobid_tmp}{'purge_job_uuid'} = $found_value[$count];}
      if($found_variable[$count] eq 'verify_job_uuid'){$main::JOBID{$jobid_tmp}{'verify_job_uuid'} = $found_value[$count];}
  	}
  	
    ##REPORT ERRORS IN CFG FILE IF FOUND
    if($return_error){
     	for $tmp(@variable_error){print "$tmp\n";}
     	for $tmp(@value_error){print "$tmp\n";}
     	&f_output("ERROR","Error in the job definition file ".$main::JOBID{$jobid_tmp}{'file'}.".",9);
    }
    
    $main::JOBNAME{&f_cstr("E",$main::JOBID{$jobid_tmp}{'name'})} = &f_cstr("D",$jobid_tmp);
  }
  &f_output("DEBUG","Configuration file successfully loaded.");
}

1;
