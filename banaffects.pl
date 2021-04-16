use strict;
use Irssi;
use Irssi::Irc;

use vars qw($VERSION %IRSSI);
$VERSION = "1.2";
%IRSSI = (
    authors     => 'Valentin Batz, Nico R. Wohlgemuth',
    contact     => 'senneth@irssi.org, nico@lifeisabug.com',
    name        => 'banaffects_sd',
    description => 'Shows affected nicks by a ban on a new ban ' .
                   'and defends yourself because IRC is serious.',
    url         => 'http://nico.lifeisabug.com/irssi/scripts/',
    licence     => 'GPLv2',
    version     => $VERSION,
);

Irssi::theme_register([
      #'ban_affects' => '%Z8c7e51Ban affects: {hilight $0-}',
   'ban_affects' => '%Z8c7e51$[-15]2 » MODE: $0: %R[%Z8c7e51+b $1%R]%Z8c7e51 affecting $3-',
   'ban_affects_t' => 'Ban {hilight $0} would affect: {hilight $1-}',
   'ban_affects_sd', 'Ban affects {hilight you}; taking care of {hilight $0}...'
]);

my $my_expando_variable = "";

sub ban_new {
   my ($chan, $ban) = @_;
   return unless $chan;
   my $server = $chan->{server};
   my $banmask = $ban->{ban};
   my $banuser = $ban->{setby};
   my $ownnick = $server->{nick};
   my $channel = $chan->{name};
   my $window = $server->window_find_item($channel);
   my $selfdefense = 0;
   my @matches;
   foreach my $nick ( sort ( $chan->nicks() ) ) {
      if (Irssi::mask_match_address( $banmask, $nick->{nick}, $nick->{host} )) {
         push (@matches, $nick->{nick});
      }
   }
   my $size = @matches;
   my $nicks = join(", ", @matches);
   $my_expando_variable = "affecting " . "\cc07nicks\co";
   if ($banuser eq $ownnick and $size > 1) {
       Irssi::print($my_expando_variable)
   };
};

sub my_expando { return $my_expando_variable };

sub clear_expando { $my_expando_variable = ""; };
#Irssi::signal_add_first("channel mode changed", \&clear_expando);

sub colored {
   foreach (0 .. 15) {
      Irssi::print("\cc$_" . $_ . "test\co");
   };
}
Irssi::expando_create("affected_nick", \&my_expando, {"ban new" => "none"});
Irssi::signal_add('ban new', \&ban_new);
Irssi::signal_add("message irc mode", \&clear_expando);
Irssi::command_bind("color", \&colored)
