package init;

###########################################################################################
#
#                                         sbackup
#                                         init
#
###########################################################################################

use strict;
use warnings;
use POSIX qw(strftime ceil);

use Exporter qw(import);
our @ISA = qw(Exporter);
our @EXPORT = qw(
									f_output get_env f_arguments 
									size2human perf2human min2time severity2id bit2oct oct2bit
									$slash $BINPATH $MODULESPATH $ETCPATH $JOBCONFIGPATH $USERSCRIPTSPATH $VARPATH $VERSIONLOGPATH $CATALOGPATH $RUNFILEPATH
									$OS_USERS $OS_GROUPS
									$cmd_ls $cmd_ln $cmd_rm $cmd_ps $cmd_sleep $cmd_cp $cmd_mv $cmd_mkdir $cmd_chmod $cmd_rsync $cmd_kill $cmd_pkill $cmd_df $cmd_which $cmd_sync $cmd_dpkg
									$cmd_lvs $cmd_lvdisplay $cmd_lvcreate $cmd_lvremove $cmd_mount $cmd_umount
									$backupserver_fqdn
							  );

##
##OUTPUT HANDLER
##
sub f_output {
	my ($msg_type,$err_msg,$additionalcode)=@_;
	$err_msg =~ s/\n$//;
	my ($sec,$min,$hour,$mday,$mon,$year, $wday,$yday,$isdst) = localtime;
	my $debug_type;
	my $debug_show = 0;
	#my $reportdate = ($year+1900).'.'.substr(($mon + 101),1,2).'.'.substr(($mday + 100),1,2).' '.substr(($hour + 100),1,2).':'.substr(($min + 100),1,2).':'.substr(($sec + 100),1,2);
	my $reportdate = substr(($hour + 100),1,2).':'.substr(($min + 100),1,2).':'.substr(($sec + 100),1,2);
	if($msg_type eq "ERROR"){
	  print STDERR "$err_msg\n";
    if($additionalcode){
    	print STDERR "\n";
    	exit $additionalcode;
    }
  }
  if($::DEBUGMODE){
    if($msg_type eq "DEBUG"){
    	$debug_type = "MSG";
			$debug_show = 1;
  	}
  	if($msg_type eq "DEBUG1"){
  		$debug_type = "ERR";
  		$debug_show = 1;
    }
    if($msg_type eq "DEBUG2" && $::p_debug >= 2){
    	$debug_type = "DET";
    	$debug_show = 1;
    }
    if($msg_type eq "DEBUG3" && $::p_debug >= 3){
    	$debug_type = "SQL";
    	$debug_show = 1;
    }
    if($msg_type eq "DEBUG4" && $::p_debug >= 4){
    	$debug_type = "DET4";
    	$debug_show = 1;
    }
  	if($msg_type eq "DEBUG5" && $::p_debug >= 5){
  		$debug_type = "DET5";
  		$debug_show = 1;
    }
    
    if($debug_show){
      if($::DEBUGFILE){
      	$::s_debugfile = $0;
  			$::s_debugfile =~ /(ob\w*)$/;
  			$::s_debugfile = $1;
    		append_log("$::LOGPATH${main::s_slash}debug$::s_slash${main::s_debugfile}.log","=\"PID".$$."\"-$debug_type-$reportdate=>$err_msg");
    	}else{
    		print "=DEBUG-$debug_type-$reportdate=>$err_msg\n";
    	}
    }
	}
  if($msg_type eq "SCREEN"){
	  print "$err_msg";
  }
#  if($msg_type eq "HTML" &&($::sv_html)){
#  	printf main::htmlfile "$err_msg\n";
#  }
} 

sub get_env{
	&f_output("DEBUG","Setting required parameters.");
	our $slash					= "/";
	
	our $BINPATH        = "/opt/sbackup".$slash;
	our $MODULESPATH    = "/opt/sbackup/modules".$slash;
	our $ETCPATH        = "/etc/opt/sbackup".$slash;
	our $JOBCONFIGPATH  = "/etc/opt/sbackup/jobs".$slash;
	our $USERSCRIPTSPATH= "/etc/opt/sbackup/userscripts".$slash;
	our $VARPATH        = "/var/opt/sbackup".$slash;
	our $VERSIONLOGPATH = "/var/opt/sbackup/versionlogs".$slash;
	our $CATALOGPATH    = "/var/opt/sbackup/catalog".$slash;
	our $RUNFILEPATH    = "/var/run/sbackup".$slash;
	my $CRONFILE        = "/etc/cron.d/sbackup";
	my $AUTOCOMPLETE    = "/usr/share/bash-completion/completions/sbackup";
	
	our $OS_USERS       = "/etc/passwd";
	our $OS_GROUPS      = "/etc/group";
	
	our $cmd_ls         = "ls";
	our $cmd_ln         = "ln -s";
	our $cmd_rm         = "rm -r";
	our $cmd_ps         = "ps";
	our $cmd_sleep      = "sleep";
	our $cmd_cp         = "cp";
	our $cmd_mv         = "mv";
	our $cmd_df         = "df";
	our $cmd_which      = "which";
	our $cmd_mkdir      = "mkdir -p";
	our $cmd_chmod      = "chmod";
	our $cmd_rsync      = "rsync";
	our $cmd_kill       = "kill";
	our $cmd_pkill      = "pkill";
	our $cmd_sync       = "sync";
	our $cmd_dpkg       = "dpkg";
	my $cmd_hostname    = "/bin/hostname";
	
	
	our $cmd_lvs        = "/sbin/lvs";
	our $cmd_lvdisplay  = "/sbin/lvdisplay";
	
	our $cmd_lvcreate   = "/sbin/lvcreate";
	our $cmd_lvremove   = "/sbin/lvremove";
	
	our $cmd_mount      = "/bin/mount";
	our $cmd_umount     = "/bin/umount";
	
	
	our $backupserver_fqdn = `$cmd_hostname -f`;
	chomp $backupserver_fqdn;
	

	if(!-d $JOBCONFIGPATH){
		system("$cmd_mkdir $JOBCONFIGPATH");
		if($? != 0){
			print "Failed to create $JOBCONFIGPATH with exit code $?.\n";
			exit 1;
		}
	}
	
	if(!-d $USERSCRIPTSPATH){
		system("$cmd_mkdir $USERSCRIPTSPATH");
		if($? != 0){
			print "Failed to create $USERSCRIPTSPATH with exit code $?.\n";
			exit 1;
		}
	}
	
	if(!-d $VERSIONLOGPATH){
		system("$cmd_mkdir $VERSIONLOGPATH");
		if($? != 0){
			print "Failed to create $VERSIONLOGPATH with exit code $?.\n";
			exit 1;
		}
	}
	
	if(!-d $CATALOGPATH){
		system("$cmd_mkdir $CATALOGPATH");
		if($? != 0){
			print "Failed to create $CATALOGPATH with exit code $?.\n";
			exit 1;
		}
	}
	
	if(!-d $RUNFILEPATH){
		system("$cmd_mkdir $RUNFILEPATH");
		if($? != 0){
			print "Failed to create $RUNFILEPATH with exit code $?.\n";
			exit 1;
		}
	}
	
	if(!-e $AUTOCOMPLETE){
		system("$cmd_ln \"${BINPATH}autocompletions\" \"$AUTOCOMPLETE\"");
		if($? != 0){
			print "Failed to create $AUTOCOMPLETE with exit code $?.\n";
			exit 1;
		}
	}
	
	if(!-f $CRONFILE){
		if(!$::PREVIEWMODE){
    	if(open(my $fh, ">>", "$CRONFILE")){
    		flock $fh,2;
    		truncate $fh,0;
    		print $fh '# '.$CRONFILE.': crontab entries for sbackup'."\n\n";
    		print $fh '0,15,30,45 * * * * root '.$BINPATH.'/sbackup -scheduler >/dev/null'."\n";
    		flock $fh,8;
    		close $fh;
    	}else{
    		f_output("ERROR","Error: Insufficient access rights.",1);
    	}
  	}
  }
}

sub min2time {
	my ($timestr)=@_;
	my $hours = int($timestr/60);
	my $minutes = $timestr - ($hours * 60);
	if(length($hours) == 1){$hours = "0".$hours;}
	if(length($minutes) == 1){$minutes = "0".$minutes;}
	return "$hours\:$minutes";
}


##
##Severity convert
##
sub severity2id{
	my ($severity)=@_;
	my @severity_list = ("Normal", "Warning", "Minor", "Major", "Critical");
	my $filter_id = 0;
	
	my $i = -1;
	for my $tmp(@severity_list){
		$i++;
		$filter_id = $i if $severity eq $tmp;
	}
	return $filter_id;
}

sub bit2oct{
	my ($bits)=@_;
	return "" if !$bits || $bits eq "";
	return "" if $bits !~ /^[rwxs-]{9}$/;
	$bits =~ s/\-/0/g;
	$bits =~ s/r|w|x|s/1/g;
	
	if($bits =~ /^(\d{3})(\d{3})(\d{3})$/){
		return oct('0b'.$1).oct('0b'.$2).oct('0b'.$3);
	}else{

		return "";
	}
}

sub oct2bit{
	my ($octs)=@_;
	my $bits = "";
	
	return "---------" if !$octs || $octs eq "";
	
	if($octs =~ /^(\d)(\d)(\d)$/){
		$bits .= "---" if $1 == 0;
		$bits .= "--x" if $1 == 1;
		$bits .= "-w-" if $1 == 2;
		$bits .= "-wx" if $1 == 3;
		$bits .= "r--" if $1 == 4;
		$bits .= "r-x" if $1 == 5;
		$bits .= "rw-" if $1 == 6;
		$bits .= "rwx" if $1 == 7;

		$bits .= "---" if $2 == 0;
		$bits .= "--x" if $2 == 1;
		$bits .= "-w-" if $2 == 2;
		$bits .= "-wx" if $2 == 3;
		$bits .= "r--" if $2 == 4;
		$bits .= "r-x" if $2 == 5;
		$bits .= "rw-" if $2 == 6;
		$bits .= "rwx" if $2 == 7;
		
		$bits .= "---" if $3 == 0;
		$bits .= "--x" if $3 == 1;
		$bits .= "-w-" if $3 == 2;
		$bits .= "-wx" if $3 == 3;
		$bits .= "r--" if $3 == 4;
		$bits .= "r-x" if $3 == 5;
		$bits .= "rw-" if $3 == 6;
		$bits .= "rwx" if $3 == 7;
	}else{
		$bits = "---------";
	}
	
	return $bits;
}

sub size2human{
	my ($size)=@_;

  return "0" if $size eq "0";
	return "N/A" if !$size || $size eq "" || $size < 0;

	my $out_size = $size." B";
	$out_size = ceil($size / 1024)." K" if $size > (100 * 1024);
	$out_size = ceil($size / 1024 / 1024)." M" if $size > (9 * 1024 * 1024);
	$out_size = ceil($size / 1024 / 1024 / 1024)." G" if $size > (9 * 1024 * 1024 * 1024);
	
	return $out_size;
}

sub perf2human{
	my ($perf)=@_;

  return "0" if $perf eq "0";
	return "N/A" if !$perf || $perf eq "" || $perf < 0;

	my $out_perf = $perf." B";
	$out_perf = ceil($perf / 1024)." K/s" if $perf > (100 * 1024);
	$out_perf = ceil($perf / 1024 / 1024)." M/s" if $perf > (9 * 1024 * 1024);
	$out_perf = ceil($perf / 1024 / 1024 / 1024)." G/s" if $perf > (9 * 1024 * 1024 * 1024);
	
	return $out_perf;
}

##
##LEVENSHTEIN
##
sub f_levenshtein {
	use List::Util qw(min);
	my ($str1, $str2) = @_;
	my @ar1 = split //, $str1;
	my @ar2 = split //, $str2;

	my @dist;
	$dist[$_][0] = $_ foreach (0 .. @ar1);
	$dist[0][$_] = $_ foreach (0 .. @ar2);

	foreach my $i (1 .. @ar1){
		foreach my $j (1 .. @ar2){
			my $cost = $ar1[$i - 1] eq $ar2[$j - 1] ? 0 : 1;
			$dist[$i][$j] = min(
			$dist[$i - 1][$j] + 1,
			$dist[$i][$j - 1] + 1,
			$dist[$i - 1][$j - 1] + $cost );
		}
	}
	return $dist[@ar1][@ar2];
}

##
##ARGUMENT HANDLER
##
sub f_arguments {
	my $arguments = shift;
  my $noofarguments = @ARGV;
  if($noofarguments eq "0"){&f_help(\%{$arguments});}
  my @val;
  
  sub f_help { #HELP FUNCTION
  	my $arguments = shift;
    print "Syntax:\n\n";
    my @arguments_sort = sort { ${$arguments}{$a}{help_display} <=> ${$arguments}{$b}{help_display} } keys %{$arguments};
    for my $tmp(@arguments_sort){
    	if(defined ${$arguments}{$tmp}{help_header} && ${$arguments}{$tmp}{help_display} > 0){
     		print "  ${$arguments}{$tmp}{help_header}\n";
    		print "\t${$arguments}{$tmp}{help_args}\n\n";
    	}
    }
    exit 1;
    return 1;
  }
  
  ##Parse all arguments
  while (@ARGV){
  	my $arg = shift @ARGV;
  	
  	if ($arg =~ /^\-(.*)$/){
  		my $arg_s = $1;
  		
  		##Check aliases
  		if(!defined ${$arguments}{$arg_s}){
    		for my $tmp(keys %{$arguments}){
    			next if !defined ${$arguments}{$tmp}{aliases};
    			@val = split /;/, ${$arguments}{$tmp}{aliases};
    			for my $tmp2(@val){
    				$arg_s = $tmp if $arg_s eq $tmp2;
    			}
    		}
  		}
  		
  		##Try to resolve incomplete/mistyped argument
  		if(!defined ${$arguments}{$arg_s}){
  			##Compare to all arguments and get number of possibilities
  			my $possible_no = 0;
  			my $possible_last = "";
  			for my $tmp(sort keys %{$arguments}){
  				if($tmp =~ /^$arg_s/){
  					$possible_no++;
  					$possible_last = $tmp;
  				}
  			}
  
  			##Error on multiple possibilities with shortened argument
  			if($possible_no > 1){
  				if(int(length($arg_s)) == 0){&f_help($arguments);}
  				print "\nSyntax error.\nShortened argument \"$arg\" have multiple possibilities:\n\n";
  				for my $tmp(sort keys %{$arguments}){
  					if($tmp =~ /^$arg_s/ && defined ${$arguments}{$tmp}{help_header}){
  						print "  ${$arguments}{$tmp}{help_header}\n";
    					print "\t${$arguments}{$tmp}{help_args}\n\n";
    				}
  				}
  				print "\n";exit 1;
  			}
  			
  			##Try to detect a typo
  			my $most_likely = "";
  			if($possible_no == 0){
  				##Use levenshtein to find typo matches
  				my %arguments_matched = ();
  				for my $tmp(keys %{$arguments}){
  					$arguments_matched{$tmp} = &f_levenshtein($arg_s,$tmp);
  					$arguments_matched{$tmp} = &f_levenshtein($arg_s,substr($tmp,0,length($arg_s))) if length($arg_s) < length($tmp) && $arguments_matched{$tmp} > &f_levenshtein($arg_s,substr($tmp,0,length($arg_s)));
  				}
  				
  				##Get most likely match for typo
  				for my $tmp(keys %arguments_matched){
  					##Discard unlikely matches
  					if(int(length($tmp) / 2) < $arguments_matched{$tmp} || int(length($arg_s) / 2) < $arguments_matched{$tmp}){
  						delete $arguments_matched{$tmp};
  						next;
  					}
  					$most_likely = $tmp if $most_likely eq "" || $arguments_matched{$tmp} < $arguments_matched{$most_likely};
  				}
  				
  				##Discard most likely match if next match is too close
  				if($most_likely ne ""){
    				for my $tmp(keys %arguments_matched){
    					next if $most_likely eq $tmp;
    					$most_likely = "" if (int($arguments_matched{$most_likely}) + 2 ) > int ($arguments_matched{$tmp});
    				}
  				}
  				
  				if($most_likely ne ""){
  					if(int $arguments_matched{$most_likely} > 2){
  						##Error on heavy typo
  						print "\nSyntax error.\nMistyped argument \"$arg\", probable argument \"-".$most_likely."\"\n";
  						print "  ${$arguments}{$most_likely}{help_header}\n";
    					print "\t${$arguments}{$most_likely}{help_args}\n\n";
  						exit 1;
  					}else{
  						##Fix typo on single match
  						$possible_no = 1;
  						$arg_s = $most_likely;
  						$arg = "-".$most_likely;
  					}
  				}elsif(int(keys %arguments_matched) > 0){
  					##Error on more possible matches
    				print "\nSyntax error.\nMistyped argument \"$arg\" have multiple possibilities:\n\n";
    				for my $tmp(sort keys %arguments_matched){
    					print "  ${$arguments}{$tmp}{help_header}\n";
    					print "\t${$arguments}{$tmp}{help_args}\n\n";
    				}
    				print "\n";exit 1;
  				}else{
  					print "\nSyntax error.\nUnknown argument \"$arg\".\n\n";&f_help($arguments);
  				}
  			}
  			
  			##Set arg when only one possibility is found
  			if($possible_no == 1){
  				if($most_likely eq ""){
  					$arg_s = $possible_last;
  					$arg = "-".$possible_last;
  				}
  			}else{
  				print "\nSyntax error.\nUnknown argument \"$arg\".\n\n";&f_help($arguments);
  			}
  		}
  		
  		##Set Argument
  		${${$arguments}{$arg_s}{var}} = 1;
  		  				
  		##Get argument values
  		my $vals_no = 0;
  		while(defined $ARGV[0] && ($ARGV[0] || $ARGV[0] eq "0") && $ARGV[0] !~ /^-/){
  			##Argument does not support values
  			if(!defined ${$arguments}{$arg_s}{val1}){
  				print "\nSyntax error.\nArgument \"$arg\" does not support values.\n\n";
  				print "  ${$arguments}{$arg_s}{help_header}\n";
    			print "\t${$arguments}{$arg_s}{help_args}\n\n";
  				exit 1;
  			}
  			$vals_no++;
  			##Too many values for specified argument
  			if(!defined ${$arguments}{$arg_s}{"val".$vals_no}){
  				print "\nSyntax error.\nToo many values for argument \"$arg\".\n\n";
  				print "  ${$arguments}{$arg_s}{help_header}\n";
    			print "\t${$arguments}{$arg_s}{help_args}\n\n";
  				exit 1;
  			}
  			my $param = shift @ARGV;
  			${${$arguments}{$arg_s}{"val".$vals_no}} = $param;
  		}
  		
  		##Missing value for specified argument
  		if(${$arguments}{$arg_s}{vals_mandatory} == 1 && defined ${$arguments}{$arg_s}{"val".($vals_no + 1)}){
  			print "\nSyntax error.\nArgument \"$arg\" is missing mandatory values.\n\n";
  			print "  ${$arguments}{$arg_s}{help_header}\n";
    		print "\t${$arguments}{$arg_s}{help_args}\n\n";
  			exit 1;
  		}
  	}else{
  		##Invalid argument entry
  		print "\nSyntax error.\nInvalid argument \"$arg\".\n\n";&f_help($arguments);
  	}
  }
  
  ##Check for argument dependency
  my $args_no = 0;
  for my $arg_s(sort keys %{$arguments}){
  	next if !defined ${${$arguments}{$arg_s}{var}};
  	next if defined ${${$arguments}{$arg_s}{var}} && ${${$arguments}{$arg_s}{var}} != 1;
  	$args_no++ if defined ${$arguments}{$arg_s}{primary} && ${$arguments}{$arg_s}{primary} == 1;
  	next if !defined ${$arguments}{$arg_s}{dependency};
  	next if defined ${$arguments}{$arg_s}{dependency} && ${$arguments}{$arg_s}{dependency} eq "";
  	
  	@val = split /;/,${$arguments}{$arg_s}{dependency};
  	my $dependency_ok = 0;
  	for my $tmp(@val){
  		$dependency_ok = 1 if defined ${${$arguments}{$tmp}{var}} && ${${$arguments}{$tmp}{var}} == 1;
  	}
  	if($dependency_ok == 0){
  		print "\nSyntax error.\nArgument \"-$arg_s\" is not usable in this combination.\n\n";exit 1;
  	}
  }
  
  if($args_no > 1){
  	my @mixed_args;
  	for my $arg_s(sort keys %{$arguments}){
  		push @mixed_args,"-".$arg_s if ${$arguments}{$arg_s}{primary} && ${${$arguments}{$arg_s}{var}};
  	}
  	print "\nSyntax error.\nArguments ".join(", ",@mixed_args)." cannot be used together.\n\n";exit 1;
  }
}

1;