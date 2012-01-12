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
use Wx qw(:id :filedialog :statictext);
use Wx::Grid;
use File::Spec;
use base 'Wx::Frame';

use Wx::Event qw(EVT_BUTTON);

sub new
{
    my $class = shift;
    my $self = $class->SUPER::new(undef, -1, 'MD5er', [-1, -1], [640, 480]);
    my $panel = Wx::Panel->new($self, -1);
    my $grid = Wx::Grid->new( $panel, -1, [10,10],[600,400]);
    $grid->CreateGrid(1,2);
    $grid->SetRowLabelSize(0);
    #my $files_label = Wx::StaticText->new( $panel, -1, 'Selected Files:', [-1, -1], [5,5], $self->style);
    my $button = Wx::Button->new($panel, -1, 'Browse...', [10, 420], [-1, -1]);
    my $callback = sub {
        my($filename) = @_;
        #Count rows and insert at correct index
        $grid->SetCellValue(1,1,$filename);
    };
    EVT_BUTTON($self, $button, \&file_chooser($callback));
    return $self;
}

sub file_chooser
{
    my ($self, $callback) = @_;
    print "Show file dialog\n";
    #Wx::
    my $dlg = Wx::FileDialog->new($self, "Select files...", '/', '', "*.*", wxFD_OPEN|wxFD_MULTIPLE);
    $dlg->ShowModal();
    my @filenames = $dlg->GetFilenames();
    my @paths = $dlg->GetPaths();
    #Build file path with file::Spec
}


1;
