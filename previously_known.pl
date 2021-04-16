use Irssi qw(servers);
#use warnings; 
use strict;
use File::Glob qw/:bsd_glob/;
use vars qw($VERSION %IRSSI);

$VERSION      = "0.2";

%IRSSI = (
      authors => "Hammett",
      contact => "freenode",
      name => "Previously_known",
      description => "Prints previous known nick for IP" .
                     "Creates a variable 'previous_nick'" .
                     "to be used in /format in 'message join." .
                     "signal." .
                     "Autosave on server disconnected" .
                     "TODO: " .
                     "work with relative path for nick.db",
      license => "Public Domain",
      url => "none"
);
my $env = $ENV{"HOME"};
my $nickdb = $env . "/.irssi/nicks.db";

if (!-e $nickdb) {truncate $nickdb,0;};
open(my $original_file, "<", $nickdb);
my @track_file = <$original_file>;
close($original_file);


#foreach my $line (@track_file) {
#   Irssi::print("$line")
#}

my $previous = "";

sub track_join {
    my ($server, $chan, $joined_nick, $address, $account, $realname) = @_;
    $joined_nick= conv($joined_nick);
    my @spl   = split(/@/, $address);
    #    my $ident = $spl[0];
    my $mask  = $spl[1];
    #($ident   = $ident) =~ s/^~//;
    #$ident    = conv($ident);

    if(!grep(/$joined_nick;$mask/, @track_file)) {
        push(@track_file, "$joined_nick;$mask\n")
     }

    my @matches;
    foreach my $line (@track_file) {
        my @saved = split(";", $line);
        my $saved_address = $saved[1];
        my $saved_nick = $saved[0];
        if (grep(/$mask/, $saved_address)) {
            push (@matches, $saved_nick) if ($saved_nick ne $joined_nick);
        }
        my $found_nicks = join(", ", @matches);
        if ($found_nicks ne "") { 
           $previous = "Previously known as: " . $found_nicks 
        } else { 
           $previous = ""
        };
     };
}

sub conv {
    my $data = $_[0];
    if (!$data) { return; }
    ($data = $data) =~ s/\]/~~/g;
    ($data = $data) =~ s/\[/@@/g;
    ($data = $data) =~ s/\^/##/g;
    ($data = $data) =~ s/\\/&&/g;
    ($data = $data) =~ s/\{/&&/g;
    return $data;
}

sub uniq {
   my %seen;
   grep !$seen{$_}++, @_;
}

sub save_to_file {
   open(my $fh, ">", $nickdb);
   @track_file = uniq(@track_file);
   foreach my $line (@track_file) {
      local $\ = "";
      print $fh "$line";
   };
   close $fh;
}

sub nick_changed {
    my ($server, $new_nick, $old_nick, $address) = @_;
    $new_nick = conv($new_nick);
    my @spl   = split(/@/, $address);
    my $mask  = $spl[1];
    #my $ident = $spl[0];
    #($ident   = $ident) =~ s/^~//;
    #$ident    = conv($ident);
    
    if(!grep(/$new_nick;$mask/, @track_file)) {
       push(@track_file, "$new_nick;$mask\n")
     }
 }

sub my_expando { $previous };

sub search_previous {
   my ($arg, $server, $witem) = @_;
   ($arg = $arg) =~ s/\s//g;
   return unless (defined $witem && $witem->{type} eq 'CHANNEL');
   my $chan = $witem->{name};
   my $found = $witem->nick_find($arg);
   if ($found ne '') {
         my @mask_found = split(/@/,$found->{host});
         my $mask = $mask_found[1];
         my @matches;
         foreach my $line (@track_file) {
              my @saved = split(";", $line);
              my $saved_address = $saved[1];
              my $saved_nick = $saved[0];
              if (grep(/$mask/, $saved_address)) {
                  push (@matches, $saved_nick) if ($saved_nick ne $arg);
              } 
          };
          my $found_nicks = join(", ", @matches);
          if ($found_nicks ne '') {
          Irssi::print("\cc03$arg\co" . " was previously known as " . "\cc04$found_nicks\co");
          } else {
              Irssi::print("No previous nicks found for " . "\cc03$arg\co")
          };
       } else {
           Irssi::print("Nick not found in channel");
    };
 }


Irssi::expando_create("previous_nick", \&my_expando, {"message join" => "none"});

Irssi::signal_add("message join", \&track_join);
Irssi::signal_add_first("server quit", \&save_to_file);
#Irssi::signal_add_first("server disconnected", \&save_to_file);
Irssi::signal_add("message nick", \&nick_changed);
Irssi::command_bind("previous_nick_save", \&save_to_file);
Irssi::command_bind("previous_nick", \&search_previous)
