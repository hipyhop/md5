package GUI::main;

use strict;
use warnings;

use Wx 0.99;
use base 'Wx::App';

sub OnInit
{
    my ($self) = @_;
    my $frame = mainFrame->new;
    $frame->Show(1);
    $self->SetExitOnFrameDelete(0) if ($^O eq 'darwin');
    1;
}

package mainFrame;
use strict;
use warnings;
use base 'Wx::Frame';

use Wx::Event qw(EVT_BUTTON);

sub new
{
    my $class = shift;
    my $self = $class->SUPER::new(undef, -1, 'MD5er', [-1, -1], [320, 200]);

    my $panel = Wx::Panel->new($self, -1);
    my $button = Wx::Button->new($panel, -1, 'Click Me!', [30, 20], [-1, -1]);
    EVT_BUTTON($self, $button, \&file_chooser);
    return $self;
}

sub file_chooser
{
    my ($self, $event) = @_;
    $self->SetTitle('Clicked');
}


1;
