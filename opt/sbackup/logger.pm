package logger;

###########################################################################################
#
#                                         sbackup
#                                         logger
#
###########################################################################################

use strict;
use warnings;
use Fcntl ':flock';
use POSIX qw(strftime);
use init;

use Exporter qw(import);
our @ISA = qw(Exporter);
our @EXPORT = qw(append_log write_log read_log
								get_history insert_history update_history delete_history
								get_runfile set_runfile update_runfile rm_runfile check_runfile
								version_log);

##
## HISTORY
##

our %table;

%{$table{"history"}} = (
    "status"=>0,
    "name"=>1,
    "start"=>2,
    "end"=>3,
    "size"=>4,
    "perf"=>5,
    "type"=>6,
    "error"=>7
  );
  
%{$table{"runfile"}} = (
    "type"=>0,
    "pid"=>1,
    "status"=>2,
    "epoch"=>3,
    "rpid"=>4
  );

sub parse_select{
	my ($from,$entry)=@_;
	my @select_request;
	my @entries = split(/,/,$entry,-1);
  my $i = 0;
  for my $tmp(@entries){
  	$select_request[$i]{'key'} = $tmp;
	  $select_request[$i]{'value'} = $table{$from}{$tmp};
	  $i++;
  }
	return @select_request;
}

sub parse_where{
	my ($from,$entry)=@_;
	my @where_request;
	my @entries = split(/,/,$entry,-1);
  my $i = 0;
  for my $tmp(@entries){
  	my @val = split(/==/,$tmp,-1);
  	$where_request[$i]{'key'} = $table{$from}{$val[0]};
	  $where_request[$i]{'value'} = $val[1];
	  $i++;
  }
	return @where_request;
}

sub get_history{
	my ($p_job,$select,$where)=@_;
	$where = "" if !defined($where);
	
	my $tmp2;
	my @val;
	my $line;
	my @cache;
	my $display_value;	
	my $return_counter = -1;
	my @returncodes;
	
  my @select_request = parse_select('history',$select);
  my @where_request  = parse_where('history',$where) if $where;
  if($p_job && -f $::VARPATH.'history_'.$p_job){
  	&f_output("DEBUG","History get, $select, $where");
    if(open(my $fh, "<", $::VARPATH.'history_'.$p_job)){
    	flock $fh,1;
    	while($line = <$fh>){
      	chomp($line);
      	@val = split '\|',$line;
      	push @cache,[@val];
    	}
    	flock $fh,8;
      close $fh;
    }else{
    	if(defined &::job_failed){
    		::job_failed("Error: Insufficient access rights.");
    	}else{
    		f_output("ERROR","Error: Insufficient access rights.",1);
    	}
    }
  
  	for my $tmp1(@cache){
  		$display_value = 1;
  		if($where){
  			for $tmp2(@where_request){
  				$display_value = 0 if $$tmp1[$$tmp2{'key'}] ne $$tmp2{'value'};
  			}
  		}
  		  		
  		if($display_value){
    		$returncodes[0] = 1;
    		$return_counter++;
    		for $tmp2(@select_request){
    			$returncodes[2][$return_counter]{$$tmp2{'key'}} = $$tmp1[$$tmp2{'value'}];
        }     
    	}
  	}
  }
	return @returncodes;
}

sub insert_history{
	my ($p_job,$insert)=@_;
	my @columns;
	my $tmp;
	my @val;
	my @returncodes;
	
	if($p_job && $insert){
		&f_output("DEBUG","History insert, $insert");
  	my @entries = split(/,/,$insert,-1);
  	for $tmp(keys %{$table{'history'}}){
  		$columns[$table{'history'}{$tmp}] = "";
  	}
  	for $tmp(@entries){
  		@val = split(/=/,$tmp,-1);
  		$columns[$table{'history'}{$val[0]}] = $val[1];
  	}
  	append_log($::VARPATH.'history_'.$p_job,join('|',@columns));
  	$returncodes[0] = 1;
	}
	return @returncodes;
}

sub update_history{
	my ($p_job,$update,$where)=@_;
	my %columns;
	my @cache;
	my $tmp;
	my $tmp2;
	my $line;
	my $change_value;
	my @val;
	my @returncodes;
	
	if( !-f $::VARPATH.'history_'.$p_job){
		print "Error: History file for $p_job does not exists.\n";
		return;
	}
	
	if($p_job && $update && $where){
		&f_output("DEBUG","History update $p_job, $update, $where");# if !$::PREVIEWMODE && $update =~ /perf=\d+\%, status==0/;
		my @where_request  = parse_where('history',$where);
  	my @entries = split(/,/,$update,-1);
  	for $tmp(@entries){
  		@val = split(/=/,$tmp,-1);
  		$columns{$table{'history'}{$val[0]}} = $val[1];
  	}
  	
  	if(!$::PREVIEWMODE){
    	if(open(my $fh, "+<", $::VARPATH.'history_'.$p_job)){
      	flock $fh,2;
      	while($line = <$fh>){
        	chomp($line);
        	@val = split '\|',$line;
        	push @cache,[@val];
      	}
      	seek $fh,0,0;
      	truncate $fh,0;
      	for my $tmp1(@cache){
      		$change_value = 1;
     			for $tmp2(@where_request){
     				$change_value = 0 if $$tmp1[$$tmp2{'key'}] ne $$tmp2{'value'};
     			}
     			if($change_value == 1){
     				for $tmp2(keys %columns){
     					$$tmp1[$tmp2] = $columns{$tmp2};
     				}
     			}
     			print $fh join("|",@{$tmp1}),"\n";
      	}
      	flock $fh,8;
        close $fh;
      }else{
      	if(defined &::job_failed){
      		::job_failed("Error: Insufficient access rights.");
      	}else{
      		f_output("ERROR","Error: Insufficient access rights.",1);
      	}
      }
  	}
  	$returncodes[0] = 1;
	}
	return @returncodes;
}

sub delete_history{
	my ($p_job,$where)=@_;
	my %columns;
	my @cache;
	my $tmp;
	my $tmp2;
	my $line;
	my $delete_value;
	my @val;
	my @returncodes;
	
	if( !-f $::VARPATH.'history_'.$p_job){
		print "Error: History file for $p_job does not exists.\n";
		return;
	}
	
	if($p_job && $where){
		&f_output("DEBUG","History delete $p_job, $where");
		my @where_request  = parse_where('history',$where);
  	
  	if(!$::PREVIEWMODE){
    	if(open(my $fh, "+<", $::VARPATH.'history_'.$p_job)){
      	flock $fh,2;
      	while($line = <$fh>){
        	chomp($line);
        	@val = split '\|',$line;
        	push @cache,[@val];
      	}
      	seek $fh,0,0;
      	truncate $fh,0;
      	for my $tmp1(@cache){
      		$delete_value = 0;
     			for $tmp2(@where_request){
     				$delete_value = 1 if $$tmp1[$$tmp2{'key'}] eq $$tmp2{'value'};
     			}
     			print $fh join("|",@{$tmp1}),"\n" if !$delete_value;
      	}
      	flock $fh,8;
        close $fh;
      }else{
      	f_output("ERROR","Error: Insufficient access rights.",1);
      }
  	}
  	$returncodes[0] = 1;
	}
	return @returncodes;
}

sub set_runfile{
	my ($p_job,$insert)=@_;
	my @columns;
	my $tmp;
	my @val;
	my @returncodes;
	
	if($p_job && $insert){
		&f_output("DEBUG","Setting runfile for job $p_job, $insert");
  	my @entries = split(/,/,$insert,-1);
  	for $tmp(keys %{$table{'runfile'}}){
  		$columns[$table{'runfile'}{$tmp}] = "";
  	}
  	for $tmp(@entries){
  		@val = split(/=/,$tmp,-1);
  		$columns[$table{'runfile'}{$val[0]}] = $val[1];
  	}
  	write_log($::RUNFILEPATH.'sbackup_'.$p_job,join('|',@columns));
  	$returncodes[0] = 1;
	}
	return @returncodes;
}

sub update_runfile{
	my ($p_job,$update)=@_;
	my %columns;
	my @cache;
	my $tmp;
	my $tmp2;
	my $line;
	my @val;
	my @returncodes;
	
	if( !-f $::RUNFILEPATH.'sbackup_'.$p_job){
		$returncodes[0] = 0;
		return @returncodes;
	}
	
	if($p_job && $update){
		&f_output("DEBUG","Runfile update $p_job, $update");
  	my @entries = split(/,/,$update,-1);
  	for $tmp(@entries){
  		@val = split(/=/,$tmp,-1);
  		$columns{$table{'runfile'}{$val[0]}} = $val[1];
  	}
  	
  	if(!$::PREVIEWMODE){
    	if(open(my $fh, "+<", $::RUNFILEPATH.'sbackup_'.$p_job)){
      	flock $fh,2;
      	while($line = <$fh>){
        	chomp($line);
        	@val = split '\|',$line;
        	push @cache,[@val];
      	}
      	seek $fh,0,0;
      	truncate $fh,0;
      	for my $tmp1(@cache){
   				for $tmp2(keys %columns){
   					$$tmp1[$tmp2] = $columns{$tmp2};
   				}
     			print $fh join("|",@{$tmp1}),"\n";
      	}
      	flock $fh,8;
        close $fh;
      }else{
      	if(defined &::job_failed){
      		::job_failed("Error: Insufficient access rights.");
      	}else{
      		f_output("ERROR","Error: Insufficient access rights.",1);
      	}
      }
  	}
  	$returncodes[0] = 1;
	}
	return @returncodes;
}

sub rm_runfile{
	my ($p_job)=@_;
	my @returncodes;
	if($p_job && -e $::RUNFILEPATH.'sbackup_'.$p_job){
		&f_output("DEBUG","Removing runfile for $p_job");
  	system("$::cmd_rm ".$::RUNFILEPATH.'sbackup_'.$p_job) if !$::PREVIEWMODE;
  	$returncodes[0] = 0;
  	$returncodes[0] = 1 if($? != 0);
	}
	return @returncodes;
}

sub get_runfile{
	my ($p_job,$select)=@_;
	my $tmp2;
	my @val;
	my $line;
	my @cache;
	my $display_value;	
	my $return_counter = -1;
	my @returncodes;
	
  my @select_request = parse_select('runfile',$select);
  if($p_job && -f $::RUNFILEPATH.'sbackup_'.$p_job){
  	&f_output("DEBUG","Runfile get, $select");
    if(open(my $fh, "<", $::RUNFILEPATH.'sbackup_'.$p_job)){
    	flock $fh,1;
    	while($line = <$fh>){
      	chomp($line);
      	@val = split '\|',$line;
      	push @cache,[@val];
    	}
    	flock $fh,8;
      close $fh;
    }else{
    	if(defined &::job_failed){
    		::job_failed("Error: Insufficient access rights.");
    	}else{
    		f_output("ERROR","Error: Insufficient access rights.",1);
    	}
    }
  
  	for my $tmp1(@cache){
  		$display_value = 1;
  		
  		if($display_value){
    		$returncodes[0] = 1;
    		$return_counter++;
    		for $tmp2(@select_request){
    			$returncodes[2][$return_counter]{$$tmp2{'key'}} = $$tmp1[$$tmp2{'value'}];
        }     
    	}
  	}
  }
	return @returncodes;
}

sub check_runfile{
	my ($p_job, $runfile)=@_;
	
  if(-f $runfile){
  	&f_output("DEBUG","Runfile found.");
  	## Get runfile data
  	my @output = &get_runfile($p_job,'status,type,epoch,pid');
  	if($output[0] && $output[2][0]{'pid'} =~ /^\d+$/){
  		## Runfile data contain PID
  		&f_output("DEBUG","Runfile pid ".$output[2][0]{'pid'});
  		## Check if PID is still running
  		system($::cmd_ps.' '.$output[2][0]{'pid'}.' >/dev/null 2>&1');
  		if($? == 0){
  			&f_output("DEBUG","Job is already running.");
  			return "Job (".$output[2][0]{'type'}.") is already running.";
  		}else{
  			## Close job if PID is no longer running
  			&f_output("DEBUG","Job is no longer running, possible crash or kill.");
  			update_history($p_job,"status=5,error=killed,perf=", "status==0");
  			rm_runfile($p_job);
  		}
  	}else{
  		## Close job if pidfile does not contain valid PID
  		&f_output("DEBUG","Runfile is faulty, removing.");
  		update_history($p_job,"status=5,error=killed,perf=", "status==0");
  		rm_runfile($p_job);
  	}
  }
  return 0;
}

##
## LOG HANDLING
##
sub append_log{
	my ($logfile,$logentry)=@_;
	&f_output("DEBUG","Append log $logfile, $logentry");# if !$::PREVIEWMODE && $logentry =~ /^[\+\-\*]/;
	return if $::PREVIEWMODE;
	chomp($logentry);
	if(open(my $fh, ">>", $logfile)){
  	flock $fh,2;
  	seek $fh,0,2;
  	print $fh "$logentry\n";
  	flock $fh,8;
  	close $fh;
	}else{
  	if(defined &::job_failed){
  		::job_failed("Error: Insufficient access rights.");
  	}else{
  		f_output("ERROR","Error: Insufficient access rights.",1);
  	}
	}
}

sub write_log{
	my ($logfile,@logentry)=@_;
	my $tmp;
	return if $::PREVIEWMODE;
	if(open(my $fh, ">>", $logfile)){
  	flock $fh,2;
  	truncate $fh,0;
  	for $tmp(@logentry){
  		chomp($tmp);
  		print $fh "$tmp\n";
  	}
  	flock $fh,8;
  	close $fh;
  }else{
  	if(defined &::job_failed){
  		::job_failed("Error: Insufficient access rights.");
  	}else{
  		f_output("ERROR","Error: Insufficient access rights.",1);
  	}
  }
}

sub read_log{
	my ($logfile)=@_;
	my @tmp = ();
	&f_output("DEBUG","Reading log $logfile");
	if(!-f $logfile){
		&f_output("DEBUG","File does not exists $logfile");
		return;
	}
	if(open(my $fh, "<", $logfile)){
  	flock $fh,1;
  	@tmp = <$fh>;
  	flock $fh,8;
  	close $fh;
  }else{
  	if(defined &::job_failed){
  		::job_failed("Error: Insufficient access rights.");
  	}else{
  		f_output("ERROR","Error: Insufficient access rights.",1);
  	}
  }
	return @tmp;
}

##
## VERSION LOG HANDLING
##
sub version_log{
	my ($severity,$process,$hostname,$message)=@_;
	f_output("ERROR","Code error: all parameters are required for version_log",1) if !$message;
	f_output("ERROR","Code error: invalid severity for version_log: $severity",1) if $severity !~ /^(normal|warning|minor|major|critical)$/i;
	f_output("ERROR","Code error: empty parameter passed to version_log",1) if !$severity || !$process || !$hostname;
	chomp($message);
	$message =~ s/^/        /g;
	$message =~ s/\n|\\n/\n        /g;
	$severity =~ s/^(\w)(.*)$/\u$1\L$2\E/;
	$process =~ s/^(.+)$/\U$1\E/;
	$hostname =~ s/^(.+)$/\L$1\E/;
	
	## Update severity level
	if(defined $::SB_ERRORLEVEL && $::SB_ERRORLEVEL ne "" && $::SB_ERRORLEVEL > 0){
  	$::SB_ERRORLEVEL = 2 if $severity eq "Warning"  && $::SB_ERRORLEVEL < 2;
  	$::SB_ERRORLEVEL = 3 if $severity eq "Minor"    && $::SB_ERRORLEVEL < 3;
  	$::SB_ERRORLEVEL = 4 if $severity eq "Major"    && $::SB_ERRORLEVEL < 4;
  	$::SB_ERRORLEVEL = 5 if $severity eq "Critical" && $::SB_ERRORLEVEL < 5;
  }
	
	&f_output("DEBUG","New version log entry [$severity] From: $process\@$hostname\n$message");
	if(!$::PREVIEWMODE){
  	if(open(my $fh, ">>", $::versionlogfile)){
    	flock $fh,2;
    	seek $fh,0,2;
    	print $fh "[$severity] From: $process\@$hostname Time: ".strftime("%d/%m/%G %H:%M:%S", localtime(time()))."\n";
    	print $fh "$message\n\n";
    	flock $fh,8;
    	close $fh;
  	}else{
    	if(defined &::job_failed){
    		::job_failed("Error: Insufficient access rights.");
    	}else{
    		f_output("ERROR","Error: Insufficient access rights.",1);
    	}
  	}
  }else{
  	if(!defined &::color){
			require Term::ANSIColor;
			import Term::ANSIColor;
		}
		my $highlight = "green";
		$highlight = "yellow" if $severity eq "Warning";
		$highlight = "cyan" if $severity eq "Minor";
		$highlight = "bright_red" if $severity eq "Major";
		$highlight = "red" if $severity eq "Critical";
  	print color($highlight)."[$severity]".color("reset")." From: $process\@$hostname Time: ".strftime("%d/%m/%G %H:%M:%S", localtime(time()))."\n";
  	print "$message\n\n";
		return;
  }
}

1;