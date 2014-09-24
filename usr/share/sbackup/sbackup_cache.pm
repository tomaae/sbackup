package sbackup_cache;  

###########################################################################################
#
#                                         sbackup
#                                          cache
#
###########################################################################################

BEGIN {
  $MODULE_NAME = "sbackup_cache";
  push @main::DEBUGHEADERS,"DEBUGGER: module: $MODULE_NAME";
  
	use Exporter   ();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

	@ISA         = qw(Exporter);
	@EXPORT      = qw(&f_get_history &f_insert_history &f_update_history &f_set_runfile &f_rm_runfile);
	%EXPORT_TAGS = ( );

	# exported package globals, as well as any optionally exported functions
	@EXPORT_OK   = qw();
}
our @EXPORT_OK;

use Fcntl ':flock';
use sbackup_init;

our %table;

%{$table{"history"}} = (
    "status"=>0,
    "name"=>1,
    "uuid"=>2,
    "start"=>3,
    "end"=>4,
    "size"=>5,
    "perf"=>6,
    "type"=>7
  );
  
%{$table{"runfile"}} = (
    "type"=>0,
    "pid"=>1,
    "status"=>2
  );

sub f_parse_select{
	my ($from,$entry)=@_;
	my @select_request;
	my $i;
	my $tmp;
	
	my @entries = split(/,/,$entry,-1);
 
  $i = 0;
  for $tmp(@entries){
  	$select_request[$i]{'key'} = $tmp;
	  $select_request[$i]{'value'} = $table{$from}{$tmp};
	  $i++;
  }

	return @select_request;
}

sub f_parse_where{
	my ($from,$entry)=@_;
	my @where_request;
	my $i;
	my $tmp;
	
	my @entries = split(/,/,$entry,-1);
 
  $i = 0;
  for $tmp(@entries){
  	my @val = split(/==/,$tmp,-1);
  	$where_request[$i]{'key'} = $table{$from}{$val[0]};
	  $where_request[$i]{'value'} = $val[1];
	  $i++;
  }

	return @where_request;
}

sub f_get_history{
	my ($p_uuid,$select,$where)=@_;
	
	my @val;
	my $tmp;
	my $line;
	my @cache;
	my $display_value;	
	my $return_counter = -1;
	my @returncodes;
	
  my @select_request = &f_parse_select('history',$select);
  my @where_request  = &f_parse_where('history',$where) if $where;
  if($p_uuid){
    open log_file,"<".$main::HISTORYPATH.$main::s_slash.'history_'.$p_uuid;
  	flock log_file,1;
  	while($line = <log_file>){
    	chomp($line);
    	@val = split '\|',$line;
    	push @cache,[@val];
  	}
  	flock log_file,8;
    close log_file;
  
  	for $val(@cache){
  		$display_value = 1;
  		if($where){
  			for $tmp(@where_request){
  				$display_value = 0 if $$val[$$tmp{'key'}] ne $$tmp{'value'};
  			}
  		}
  		  		
  		if($display_value){
    		$returncodes[0] = 1;
    		$return_counter++;
    		for $tmp(@select_request){
    			$returncodes[2][$return_counter]{$$tmp{'key'}} = $$val[$$tmp{'value'}];
        }     
    	}
  	}
  }
	
	##Select output
	return @returncodes;
}

sub f_insert_history{
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
  	append_log($main::HISTORYPATH.$main::s_slash.'history_'.$p_uuid,join('|',@columns));
  	
  	$returncodes[0] = 1;
	}
	return @returncodes;
}

sub f_update_history{
	my ($p_uuid,$update,$where)=@_;
	my %columns;
	my @cache;
	my $tmp;
	my $line;
	my @val;
	my @returncodes;
	
	if($p_uuid && $update && $where){
		my @where_request  = &f_parse_where('history',$where);
  	my @entries = split(/,/,$update,-1);
  	for $tmp(@entries){
  		@val = split(/=/,$tmp,-1);
  		$columns{$table{'history'}{$val[0]}} = $val[1];
  	}
  	
  	open log_file,"+<".$main::HISTORYPATH.$main::s_slash.'history_'.$p_uuid;
  	flock log_file,2;
  	
  	while($line = <log_file>){
    	chomp($line);
    	@val = split '\|',$line;
    	push @cache,[@val];
  	}

  	seek log_file,0,0;
  	truncate log_file,0;
  	for $val(@cache){
  		$change_value = 1;
 			for $tmp(@where_request){
 				$change_value = 0 if $$val[$$tmp{'key'}] ne $$tmp{'value'};
 			}
 			if($change_value == 1){
 				for $tmp(keys %columns){
 					$$val[$tmp] = $columns{$tmp};
 				}
 			}
 			print log_file join("|",@{$val}),"\n";
  	}
  	
  	flock log_file,8;
    close log_file;
  	
  	$returncodes[0] = 1;
	}
	return @returncodes;
}

sub f_set_runfile{
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
  	write_log($main::RUNFILEPATH.$main::s_slash.'sbackup_'.$p_uuid,join('|',@columns));
  	
  	$returncodes[0] = 1;
	}
	return @returncodes;
}

sub f_rm_runfile{
	my ($p_uuid)=@_;
	if($p_uuid && -e $main::RUNFILEPATH.$main::s_slash.'sbackup_'.$p_uuid){
  	system("$main::cmd_rm ".$main::RUNFILEPATH.$main::s_slash.'sbackup_'.$p_uuid);
  	$returncodes[0] = 0;
  	$returncodes[0] = 1 if($? != 0);
	}
	return @returncodes;
}

1;