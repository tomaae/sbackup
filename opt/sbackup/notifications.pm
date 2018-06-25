package notifications;

###########################################################################################
#
#                                         sbackup
#                                 notifications integration
#
###########################################################################################

use strict;
use warnings;
use POSIX qw(strftime ceil);
use Email::Sender::Simple qw(sendmail);
#use Email::Sender;
use Email::MIME;
use Email::MIME::CreateHTML;
use init;
use logger;


use Exporter qw(import);
our @ISA = qw(Exporter);
our @EXPORT = qw(notify_email);

##
## notify_email
##
sub notify_email{
	my ($subj,$job,$version,$body)=@_;
  my $subject   = "Sync Backup - $subj";
  my $sender    = 'sbackup.notifications@'.$::backupserver_fqdn;
  my $recipient = 'tomas.ebringer@me.com';
  my $html = "";
  my $plain_text = "";

  $html .= "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\"><html xmlns=\"http://www.w3.org/1999/xhtml\"><head><META HTTP-EQUIV=\"Content-Type\" CONTENT=\"text/html; charset=UTF-8\"><META http-equiv=\"X-UA-Compatible\" content=\"IE=edge\" /><style type=\"text/css\">";
  $html .= "table tr td {border:1px solid #B0B0B0;background-color:#F5F5F5;}\ntable tr th {border:1px solid #B0B0B0;background-color:#DCDCDC;}\n";
  $html .= ".coml {color:#00FF00;}\n.warn {color:#FFD700;}\n.mino {color:#00CED1;}\n.majo {color:#FF0000;}\n.crit {color:#8B0000;}\n.prog {color:#CCCCCC;}\n.que {color:#CCCCCC;}\n";
  $html .= "</style></head><body bgcolor=\"white\" width=\"100%\"><h1 align=center>$subj</h1>\n";
  
  if($body && $body ne ""){
  	$body =~ s/\n/\<br\/\>/g;
  	$html .= $body;
  	$html .= "<br/><br/>";
  }
  
  ## List version detail
  if($version){
  	$html .= '<table width="100%" border="0" cellspacing="0" cellpadding="3">';
  	$html .= email_version($job,$version);
  	$html .= '</table><br/><br/>';
  }
  
  ## List job history
  if($job){
  	$html .= '<table width="100%" border="0" cellspacing="0" cellpadding="3">';
  	$html .= email_history($job);
  	$html .= '</table>';
  }

  $html .= "</body></html>\n";



	my $email = Email::MIME->create_html(
    header => [
      To      => $recipient,
      From    => $sender,
      Subject => $subject
    ],
    body => $html,
    text_body => $plain_text
	);
  
  # Debugging; this should be controlled by a "verbose" flag
	print STDERR $email->as_string if $::DEBUGMODE;

  my $response = sendmail($email);
  if(!$response){
     print STDERR "An error occurred, got $response as response from 'sendmail: $Mail::Sendmail::error'\n";
     print STDERR $Mail::Sendmail::log;
     return "An error occurred, got $response as response from 'sendmail: $Mail::Sendmail::error'\n".$Mail::Sendmail::log;
  }else{
     return 0;
  }
  
}

##
## email_version
##
sub email_version{
	my ($p_job,$p_version)=@_;
	my $output = "";
	
	my @tmp = ::get_history($p_job,'status,name,start,end,error,size,perf,type','start=='.$p_version);
	return "" if !$tmp[0];
	
  ## Format Size/Perf
  my $out_size = "N/A";
  my $out_perf = "N/A";
  if($tmp[2][0]{'type'} eq "backup" || $tmp[2][0]{'type'} eq "copy"){
  	$out_size = size2human($tmp[2][0]{'size'});
  	
  	if($tmp[2][0]{'perf'} ne "" && $tmp[2][0]{'perf'} !~ /%$/ && $tmp[2][0]{'perf'} >= 0){
  		$out_perf = perf2human($tmp[2][0]{'perf'});
  	}elsif($tmp[2][0]{'perf'} =~ /%$/){
  		$out_perf = $tmp[2][0]{'perf'};
  	}
  }

  ## Version
  my $out_version;
  $out_version = strftime("%G/%m/%d-%H%M%S", localtime($tmp[2][0]{'start'})) if $tmp[2][0]{'start'} ne "";

  ## Start/end time
  my $out_start = "N/A";
  my $out_end = "N/A";
  $out_start = strftime("%a, %d/%m/%G %H:%M:%S", localtime($tmp[2][0]{'start'})) if $tmp[2][0]{'start'} ne "";
  $out_end = strftime("%a, %d/%m/%G %H:%M:%S", localtime($tmp[2][0]{'end'})) if $tmp[2][0]{'end'} ne "";

  ## Type
  my $out_type = "N/A";
  $out_type = "Backup" if $tmp[2][0]{'type'} eq "backup";
  $out_type = "Copy" if $tmp[2][0]{'type'} eq "copy";
  $out_type = "Restore" if $tmp[2][0]{'type'} eq "restore";
  $out_type = "Purge" if $tmp[2][0]{'type'} eq "purge";
  $out_type = "Migration" if $tmp[2][0]{'type'} eq "migration";
  $out_type = "Verify" if $tmp[2][0]{'type'} eq "verify";

  ## Parse status
  my $out_status = "N/A";
  $out_status = "Running" if $tmp[2][0]{'status'} eq "0";
  $out_status = "Completed" if $tmp[2][0]{'status'} eq "1";
  $out_status = "Completed/Warnings" if $tmp[2][0]{'status'} eq "2";
  $out_status = "Completed/Errors" if $tmp[2][0]{'status'} eq "3";
  $out_status = "Completed/Failures" if $tmp[2][0]{'status'} eq "4";
  $out_status = "Failed" if $tmp[2][0]{'status'} eq "5";
  $out_status = "Aborted" if $tmp[2][0]{'status'} eq "6";

  if($out_status eq "Running" && $out_perf =~ /%$/){
  	$out_status .= " ".$out_perf;
  	$out_perf = "N/A";
  }

  ## Parse status
  my $out_error = "";
  $out_error = $tmp[2][0]{'error'} if $tmp[2][0]{'error'};
  
  $output .= "<tr><th>Job name</th><td>$tmp[2][0]{'name'}</td></tr>";
  $output .= "<tr><th>Job type</th><td>$out_type</td></tr>";
  $output .= "<tr><th>Status</th><td>$out_status</td></tr>";
  $output .= "<tr><th>Error</th><td>$out_error</td></tr>" if $out_error;
  $output .= "<tr><th>Version</th><td>$out_version</td></tr>";
  $output .= "<tr><th>Start time</th><td>$out_start</td></tr>";
  $output .= "<tr><th>End time</th><td>$out_end</td></tr>";
  $output .= "<tr><th>Size</th><td>$out_size</td></tr>";
  $output .= "<tr><th>Performance</th><td>$out_perf</td></tr>";
  $output .= "<tr><td colspan=\"2\" style=\"background-color:#DCDCDC;\">Messages higher than Warning:";

  ##
  ## Get version log
  ##
  if(-f $::SESSIONLOGPATH.$p_job."_".$p_version.".log"){
    my $highlight = "";
    my $severity = "";
    my $filter_inmsg = 0;
    my $filter_id = 2;
    my $msg_found = 0;
    for my $tmp(&read_log($::SESSIONLOGPATH.$p_job."_".$p_version.".log")){
    	## Filter messages
    	## End of message
    	if($filter_inmsg){
    		if($tmp !~ /^\[(Normal|Warning|Minor|Major|Critical)\] / && $tmp !~ /^        / ){
    			$filter_inmsg = 0;
    		}
    	}
    	## Start of message
    	if($tmp =~ /^\[(Normal|Warning|Minor|Major|Critical)\] /){
    		if(severity2id($1) >= $filter_id){
    			$filter_inmsg = 1;
    			$msg_found = 1;
    			$output =~ s/(\<br\/\>)+$//;
    			$output .= "</td></tr><tr><td colspan=\"2\">";
    		}
    	}
    	next if !$filter_inmsg;
    	
    	## Severity colors
    	if($tmp =~ /^\[(\w+)\] /){
    		$severity = $1;
    		$tmp =~ s/^\[$severity\]//;
    		$tmp = '<span class="coml">['.$severity.']</span>'.$tmp if $severity eq "Normal";
    		$tmp = '<span class="warn">['.$severity.']</span>'.$tmp if $severity eq "Warning";
    		$tmp = '<span class="mino">['.$severity.']</span>'.$tmp if $severity eq "Minor";
    		$tmp = '<span class="majo">['.$severity.']</span>'.$tmp if $severity eq "Major";
    		$tmp = '<span class="crit">['.$severity.']</span>'.$tmp if $severity eq "Critical";
    	}
    	$tmp =~ s/\n/\<br\/\>/g;
    	$tmp =~ s/^        /&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;/;
    	$output .= $tmp;
    }
    $output .= "</td></tr><tr><td colspan=\"2\">No messages to display." if !$msg_found;
  }else{
  	$output .= "</td></tr><tr><td colspan=\"2\">Job log is not available.";
  }
  $output .= "</td></tr>" if $output !~ s/\<tr\>\<td colspan=\"2\"\>$//;
  return $output;
}


##
## email_history
##
sub email_history{
	my ($p_job)=@_;
	my $output = "<tr><th>Type</th><th>Status</th><th>Start time</th><th>Time</th><th>Size</th><th>Perf</th></tr>";

  ##
  ## Display history
  ##
  my @tmp_history = &get_history($p_job,'status,name,start,end,size,perf,type');
  for my $tmp(@{$tmp_history[2]}){

  	##Status
  	my $out_status = "";
  	#$out_status = "Err:".$$tmp{'status'} if $$tmp{'status'} ne "1" && $$tmp{'status'} ne "0";
  	$out_status = "Running" if $$tmp{'status'} eq "0";
    $out_status = "Completed" if $$tmp{'status'} eq "1";
    $out_status = "Completed/Warnings" if $$tmp{'status'} eq "2";
    $out_status = "Completed/Errors" if $$tmp{'status'} eq "3";
    $out_status = "Completed/Failures" if $$tmp{'status'} eq "4";
    $out_status = "Failed" if $$tmp{'status'} eq "5";
    $out_status = "Aborted" if $$tmp{'status'} eq "6";
    
    $out_status .= " ".$1."%" if $$tmp{'status'} eq "0" && $$tmp{'perf'} =~ / ?(\d+)? ?%$/;
  	
  	##Format job type
  	my $out_type = "N/A";
  	$out_type = "Backup" if $$tmp{'type'} eq "backup";
  	$out_type = "Copy" if $$tmp{'type'} eq "copy";
  	$out_type = "Restore" if $$tmp{'type'} eq "restore";
  	$out_type = "Purge" if $$tmp{'type'} eq "purge";
  	$out_type = "Migration" if $$tmp{'type'} eq "migration";
  	$out_type = "Verify" if $$tmp{'type'} eq "verify";
  	
  	##Format start/end datetime
  	my $out_start = "N/A";
  	my $out_time = "N/A";
  	$out_start = strftime("%a, %d/%m/%G %H:%M", localtime($$tmp{'start'})) if $$tmp{'start'} ne "";
  	$out_time = min2time(ceil(($$tmp{'end'} - $$tmp{'start'})/60)) if $$tmp{'end'} ne "";
  	
  	##Format Size/Perf
  	my $out_size = "N/A";
  	my $out_perf = "N/A";
  	if($$tmp{'type'} eq "backup" || $$tmp{'type'} eq "copy"){
  		$out_size = size2human($$tmp{'size'});
  		
  		if($$tmp{'perf'} ne "" && $$tmp{'perf'} !~ /%$/ && $$tmp{'perf'} >= 0){
  			$out_perf = perf2human($$tmp{'perf'});
  		}elsif($$tmp{'perf'} =~ /%$/){
  			$out_perf = $$tmp{'perf'};
  		}
  	}
  	
  	$output .= "<tr><td>$out_type</td><td>$out_status</td><td>$out_start</td><td>$out_time</td><td>$out_size</td><td>$out_perf</td></tr>";
  }

  return $output;
}



1;