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

use Exporter qw(import);
our @ISA = qw(Exporter);
our @EXPORT = qw(append_log write_log read_log
								get_history insert_history update_history set_runfile rm_runfile);

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
    "type"=>6
  );
  
%{$table{"runfile"}} = (
    "type"=>0,
    "pid"=>1,
    "status"=>2
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
	my ($p_uuid,$select,$where)=@_;
	my $tmp2;
	my @val;
	my $line;
	my @cache;
	my $display_value;	
	my $return_counter = -1;
	my @returncodes;
	
  my @select_request = parse_select('history',$select);
  my @where_request  = parse_where('history',$where) if $where;
  if($p_uuid && -f $main::VARPATH.'history_'.$p_uuid){
    open log_file,"<${main::VARPATH}history_${p_uuid}";
  	flock log_file,1;
  	while($line = <log_file>){
    	chomp($line);
    	@val = split '\|',$line;
    	push @cache,[@val];
  	}
  	flock log_file,8;
    close log_file;
  
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
	my ($p_uuid,$insert)=@_;
	my @columns;
	my $tmp;
	my @val;
	my @returncodes;
	
	if($p_uuid && $insert){
  	my @entries = split(/,/,$insert,-1);
  	for $tmp(keys %{$table{'history'}}){
  		$columns[$table{'history'}{$tmp}] = "";
  	}
  	for $tmp(@entries){
  		@val = split(/=/,$tmp,-1);
  		$columns[$table{'history'}{$val[0]}] = $val[1];
  	}
  	append_log($main::VARPATH.'history_'.$p_uuid,join('|',@columns));
  	$returncodes[0] = 1;
	}
	return @returncodes;
}

sub update_history{
	my ($p_uuid,$update,$where)=@_;
	my %columns;
	my @cache;
	my $tmp;
	my $tmp2;
	my $line;
	my $change_value;
	my @val;
	my @returncodes;
	
	if($p_uuid && $update && $where){
		my @where_request  = parse_where('history',$where);
  	my @entries = split(/,/,$update,-1);
  	for $tmp(@entries){
  		@val = split(/=/,$tmp,-1);
  		$columns{$table{'history'}{$val[0]}} = $val[1];
  	}
  	
  	open log_file,"+<".$main::VARPATH.'history_'.$p_uuid;
  	flock log_file,2;
  	while($line = <log_file>){
    	chomp($line);
    	@val = split '\|',$line;
    	push @cache,[@val];
  	}
  	seek log_file,0,0;
  	truncate log_file,0;
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
 			print log_file join("|",@{$tmp1}),"\n";
  	}
  	flock log_file,8;
    close log_file;
  	$returncodes[0] = 1;
	}
	return @returncodes;
}

sub set_runfile{
	my ($p_uuid,$insert)=@_;
	my @columns;
	my $tmp;
	my @val;
	my @returncodes;
	
	if($p_uuid && $insert){
  	my @entries = split(/,/,$insert,-1);
  	for $tmp(keys %{$table{'runfile'}}){
  		$columns[$table{'runfile'}{$tmp}] = "";
  	}
  	for $tmp(@entries){
  		@val = split(/=/,$tmp,-1);
  		$columns[$table{'runfile'}{$val[0]}] = $val[1];
  	}
  	write_log($main::RUNFILEPATH.'sbackup_'.$p_uuid,join('|',@columns));
  	$returncodes[0] = 1;
	}
	return @returncodes;
}

sub rm_runfile{
	my ($p_uuid)=@_;
	my @returncodes;
	if($p_uuid && -e $main::RUNFILEPATH.'sbackup_'.$p_uuid){
  	system("$main::cmd_rm ".$main::RUNFILEPATH.'sbackup_'.$p_uuid);
  	$returncodes[0] = 0;
  	$returncodes[0] = 1 if($? != 0);
	}
	return @returncodes;
}

##
## LOG HANDLING
##
sub append_log{
	my ($logfile,$logentry)=@_;
	return if $main::SIMULATEMODE;
	chomp($logentry);
	open log_file,">>$logfile" or die "Error: Insufficient access rights\n";
	flock log_file,2;
	seek log_file,0,2;
	print log_file "$logentry\n";
	flock log_file,8;
	close log_file;
}

sub write_log{
	my ($logfile,@logentry)=@_;
	my $tmp;
	open log_file,">>$logfile" or die "Error: Insufficient access rights\n";
	flock log_file,2;
	truncate log_file,0;
	for $tmp(@logentry){
		chomp($tmp);
		print log_file "$tmp\n" if !$main::SIMULATEMODE;
	}
	flock log_file,8;
	close log_file;
}

sub read_log{
	my ($logfile)=@_;
	open log_file,"<$logfile";
	flock log_file,1;
	my @tmp = <log_file>;
	flock log_file,8;
	close log_file;
	return @tmp;
}

1;