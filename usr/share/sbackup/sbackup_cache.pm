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
	@EXPORT      = qw(&f_get_history);
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
    "pid"=>1
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

1;