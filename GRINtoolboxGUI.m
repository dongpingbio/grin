function [] = GRINtoolboxGUI(varargin)
%% GRINtoolboxGUI.m - GRIN LENS IMAGING TOOLBOX
%{
% 
% Syntax
% -----------------------------------------------------
%     GRINtoolboxGUI()
% 
% 
% Description
% -----------------------------------------------------
% 
%     GRINtoolboxGUI() is run with no arguments passed in. The user
%     will be prompted to select a directory which contains the image data
%     tif stack along with the corresponding xls file.
%     
% 
% Useage Definitions
% -----------------------------------------------------
% 
%     GRINtoolboxGUI()
%         launches a GUI to process image stack data from GRIN lens
%         experiments
%  
% 
% 
% Example
% -----------------------------------------------------
% 
%     TBD
% 
% 
% See Also
% -----------------------------------------------------
% >> web('http://bradleymonk.com/grintoolbox')
% >> web('http://imagej.net/Miji')
% >> web('http://bigwww.epfl.ch/sage/soft/mij/')
% 
% 
% Attribution
% -----------------------------------------------------
% % Created by: Bradley Monk
% % email: brad.monk@gmail.com
% % website: bradleymonk.com
% % 2016.07.04
%}
%----------------------------------------------------

clc; close all; clear all; clear java;
% clearvars -except varargin

% Change the current folder to the folder of this .m file.
global thisfilepath
thisfile = 'GRINtoolboxGUI.m';
thisfilepath = fileparts(which(thisfile));
cd(thisfilepath);


global isbrad
upath = userpath;
isbrad = strcmp('/Users/bradleymonk',upath(1:18));
if ~isbrad
    addpath(genpath(thisfilepath))
    % rmpath(genpath([thisfilepath,'/.git']))
end

disp('WELCOME TO THE GRIN LENS IMAGING TOOLBOX')

%% MANUALLY SET PER-SESSION PATH PARAMETERS IF WANTED (OPTIONAL)

global imgfilename imgpathname xlsfilename xlspathname
global lickfilename lickpathname

if isbrad
imgfilename = 'gc33_031816g.tif';
imgpathname = '/Users/bradleymonk/Documents/MATLAB/myToolbox/LAB/grin/gcdata/';
xlsfilename = 'gc33_031816.xlsx';
xlspathname = '/Users/bradleymonk/Documents/MATLAB/myToolbox/LAB/grin/gcdata/';
lickfilename = 'gc33_031916_lick.xlsx';
lickpathname = '/Users/bradleymonk/Documents/MATLAB/myToolbox/LAB/grin/gcdata/';

% imgfilename = 'gc33_032316g.tif';
% imgpathname = '/Users/bradleymonk/Documents/MATLAB/myToolbox/LAB/grin/gcdata/';
% xlsfilename = 'gc33_032316.xlsx';
% xlspathname = '/Users/bradleymonk/Documents/MATLAB/myToolbox/LAB/grin/gcdata/';
end


%% ESTABLISH GLOBALS AND SET STARTING VALUES

global mainguih imgLogo

global IMG GRINstruct GRINtable
global xlsN xlsT xlsR
global lickN LICK %lickT lickR
global IMGraw

global frame_period framesUncomp CS_type US_type delaytoCS CS_length compressFrms
global total_trials framesPerTrial secPerFrame framesPerSec secondsPerTrial 
global total_frames CS_lengthFrames


global cropAmount IMGfactors blockSize previewNframes customFunOrder 
cropAmount = 18;
IMGfactors = 1;
blockSize = 22;
previewNframes = 25;
customFunOrder = 1;

global stimtype stimnum CSUSvals
% CSxUS:1  CS:2  US:3
stimnum = 1;
stimtype = 'CS'; 
CSUSvals = {'CS','US'};


global CSonset CSoffset USonset USoffset CSUSonoff
global CSonsetDelay baselineTime
CSonsetDelay = 10;
baselineTime = 10;


global smoothHeight smoothWidth smoothSD smoothRes
smoothHeight = .8;
smoothWidth = 9;
smoothSD = .14;
smoothRes = .1;


global muIMGS phGRIN previewStacknum
global IMGcMax IMGcMaxInd IMGcMin IMGcMinInd
muIMGS = [];
previewStacknum = 25;


global confile confilefullpath
confile = 'gcconsole.txt';
diary(confile)
disp('CONSOLE LOGGING ON.')
diary off
confilefullpath = which(confile,'-all');
delete(confile)


% -----------------------------------------------------------------
%%     INITIATE GUI HANDLES AND CREATE SUBMENU GUI FIGURE
% -----------------------------------------------------------------
% INITIAL SUBMENU GUI SETUP (GRIN TOOLBOX ~ MOTION CORRECTION)

initmenuh = figure('Units','normalized','OuterPosition',[.25 .4 .4 .2], ...
    'BusyAction', 'cancel','Menubar', 'none',...
    'Name', 'GRIN analysis', 'Tag', 'GRIN analysis');

grinlenstoolboxh = uicontrol('Parent', initmenuh, 'Units','normalized', 'Position', [.03 .05 .47 .9],...
    'String', 'Start GRIN lens toolbox', 'FontSize', 16, 'Tag', 'Start GRIN lens toolbox',...
    'Callback', @grinlenstoolbox);

motioncorrectionh = uicontrol('Parent', initmenuh, 'Units','normalized', 'Position', [.52 .51 .45 .44],...
    'String', 'Perform motion correction', 'FontSize', 14, 'Tag', 'Perform motion correction',...
    'Callback', @motioncorrection);


formatXLSH = uicontrol('Parent', initmenuh, 'Units','normalized', 'Position', [.52 .05 .45 .44],...
    'String', 'Multiformat XLS sheets', 'FontSize', 14, 'Tag', 'Multiformat XLS sheets',...
    'Callback', @formatXLS);



%########################################################################
%%              MAIN FLIM ANALYSIS GUI WINDOW SETUP 
%########################################################################

% mainguih.CurrentCharacter = '+';
mainguih = figure('Units', 'normalized','Position', [.05 .1 .85 .65], 'BusyAction',...
    'cancel', 'Name', 'mainguih', 'Tag', 'mainguih','Visible', 'Off'); 
     % 'KeyPressFcn', {@keypresszoom,1}, 'CloseRequestFcn',{@mainGUIclosereq}
     % intimagewhtb = uitoolbar(mainguih);


% -------- MAIN FIGURE WINDOW --------
haxGRIN = axes('Parent', mainguih, 'NextPlot', 'replacechildren',...
    'Position', [0.01 0.02 0.40 0.85], 'PlotBoxAspectRatio', [1 1 1], ...
    'XColor','none','YColor','none','YDir','reverse'); 
    % ,'XDir','reverse',...
    
% -------- IMPORT IMAGE STACK & EXCEL DATA BUTTON --------
importimgstackH = uicontrol('Parent', mainguih, 'Units', 'normalized', ...
    'Position', [0.01 0.90 0.40 0.08], 'FontSize', 14, ...
    'String', 'Import Image Stack & Excel Data', ...
    'Callback', @importimgstack);



imgsliderH = uicontrol('Parent', mainguih, 'Units', 'normalized','Style','slider',...
	'Max',100,'Min',1,'Value',1,'SliderStep',[0.01 0.10],...
	'Position', [0.01 0.86 0.40 0.03], 'Callback', @imgslider);






%----------------------------------------------------
%           IMAGE PROCESSING PANEL
%----------------------------------------------------
IPpanelH = uipanel('Title','Image Processing','FontSize',10,...
    'BackgroundColor',[.95 .95 .95],...
    'Position', [0.43 0.25 0.35 0.73]); % 'Visible', 'Off',



runallIPH = uicontrol('Parent', IPpanelH, 'Units', 'normalized', ...
    'Position', [0.03 0.86 0.95 0.10], 'FontSize', 13, 'String', 'Run All Selected Processes',...
    'Callback', @runallIP, 'Enable','off'); 

checkbox1H = uicontrol('Parent', IPpanelH,'Style','checkbox','Units','normalized',...
    'Position', [.02 0.71 .05 .05] ,'String','', 'Value',1);
checkbox2H = uicontrol('Parent', IPpanelH,'Style','checkbox','Units','normalized',...
    'Position', [.02 0.61 .05 .05] ,'String','', 'Value',1);
checkbox3H = uicontrol('Parent', IPpanelH,'Style','checkbox','Units','normalized',...
    'Position', [.02 0.51 .05 .05] ,'String','', 'Value',1);
checkbox4H = uicontrol('Parent', IPpanelH,'Style','checkbox','Units','normalized',...
    'Position', [.02 0.41 .05 .05] ,'String','', 'Value',1);
checkbox5H = uicontrol('Parent', IPpanelH,'Style','checkbox','Units','normalized',...
    'Position', [.02 0.31 .05 .05] ,'String','', 'Value',1);
checkbox6H = uicontrol('Parent', IPpanelH,'Style','checkbox','Units','normalized',...
    'Position', [.02 0.21 .05 .05] ,'String','', 'Value',1);
checkbox7H = uicontrol('Parent', IPpanelH,'Style','checkbox','Units','normalized',...
    'Position', [.02 0.11 .05 .05] ,'String','', 'Value',1);


smoothimgH = uicontrol('Parent', IPpanelH, 'Units', 'normalized', ...
    'Position', [0.08 0.70 0.60 0.08], 'FontSize', 13, 'String', 'Smooth Images',...
    'Callback', @smoothimg, 'Enable','off'); 
smoothimgtxtH = uicontrol('Parent', IPpanelH, 'Style', 'Text', 'Units', 'normalized',...
    'Position', [0.71 0.76 0.27 0.03], 'FontSize', 11,'String', 'Smooth Amount (std)');
smoothimgnumH = uicontrol('Parent', IPpanelH, 'Style', 'Edit', 'Units', 'normalized', ...
    'Position', [0.71 0.71 0.27 0.05], 'FontSize', 13); 



cropimgH = uicontrol('Parent', IPpanelH, 'Units', 'normalized', ...
    'Position', [0.08 0.60 0.60 0.08], 'FontSize', 13, 'String', 'Crop Images',...
    'Callback', @cropimg, 'Enable','off'); 
cropimgtxtH = uicontrol('Parent', IPpanelH, 'Style', 'Text', 'Units', 'normalized',...
    'Position', [0.71 0.66 0.27 0.03], 'FontSize', 11,'String', 'Crop Amount (pxl)');
cropimgnumH = uicontrol('Parent', IPpanelH, 'Style', 'Edit', 'Units', 'normalized', ...
    'Position', [0.71 0.61 0.27 0.05], 'FontSize', 13); 



imgblocksH = uicontrol('Parent', IPpanelH, 'Units', 'normalized', ...
    'Position', [0.08 0.50 0.60 0.08], 'FontSize', 13, 'String', 'Block-Segment Images',...
    'Callback', @imgblocks, 'Enable','off'); 
imgblockstxtH = uicontrol('Parent', IPpanelH, 'Style', 'Text', 'Units', 'normalized',...
    'Position', [0.71 0.56 0.27 0.03], 'FontSize', 10,'String', 'Tile Size (pxl)');
imgblockspopupH = uicontrol('Parent', IPpanelH,'Style', 'popup',...
    'Units', 'normalized', 'String', {'20','2','1'},...
    'Position', [0.70 0.505 0.28 0.05],...
    'Callback', @imgblockspopup);


reshapeDataH = uicontrol('Parent', IPpanelH, 'Units', 'normalized', ...
    'Position', [0.08 0.40 0.60 0.08], 'FontSize', 13, 'String', 'Reshape stack by trial (4D) ',...
    'Callback', @reshapeData, 'Enable','off'); 
unshapeDataH = uicontrol('Parent', IPpanelH, 'Units', 'normalized', ...
    'Position', [0.71 0.41 0.27 0.06], 'FontSize', 10, 'String', 'Undo reshape (3D) ',...
    'Callback', @unshapeData, 'Enable','off'); 



alignCSFramesH = uicontrol('Parent', IPpanelH, 'Units', 'normalized', ...
    'Position', [0.08 0.30 0.60 0.08], 'FontSize', 13, 'String', 'Align frames by CS onset',...
    'Callback', @alignCSframes, 'Enable','off');
alignCSFramestxtH = uicontrol('Parent', IPpanelH, 'Style', 'Text', 'Units', 'normalized',...
    'Position', [0.71 0.36 0.27 0.03], 'FontSize', 11,'String', 'Delay to CS onset (s)');
alignCSFramesnumH = uicontrol('Parent', IPpanelH, 'Style', 'Edit', 'Units', 'normalized', ...
    'Position', [0.71 0.31 0.27 0.05], 'FontSize', 13); 



dFoverFH = uicontrol('Parent', IPpanelH, 'Units', 'normalized', ...
    'Position', [0.08 0.20 0.60 0.08], 'FontSize', 13, 'String', 'Compute dF / F',...
    'Callback', @dFoverF, 'Enable','off'); 
dFoverFtxtH = uicontrol('Parent', IPpanelH, 'Style', 'Text', 'Units', 'normalized',...
    'Position', [0.71 0.26 0.27 0.03], 'FontSize', 11,'String', 'Baseline time (s)');
dFoverFnumH = uicontrol('Parent', IPpanelH, 'Style', 'Edit', 'Units', 'normalized', ...
    'Position', [0.71 0.21 0.27 0.05], 'FontSize', 13);



timepointMeansH = uicontrol('Parent', IPpanelH, 'Units', 'normalized', ...
    'Position', [0.08 0.10 0.60 0.08], 'FontSize', 13, 'String', 'Compute trial means ',...
    'Callback', @timepointMeans, 'Enable','off');              
CSUSpopupH = uicontrol('Parent', IPpanelH,'Style', 'popup',...
    'Units', 'normalized', 'String', {'CS','US'},...
    'Position', [0.70 0.105 0.28 0.05],...
    'Callback', @CSUSpopup);


              

%----------------------------------------------------
%           DATA GRAPHS AND FIGURES PANEL
%----------------------------------------------------
graphspanelH = uipanel('Title','Graphs and Figures','FontSize',10,...
    'BackgroundColor',[.95 .95 .95],...
    'Position', [0.43 0.02 0.35 0.20]); % 'Visible', 'Off',
              
getROIstatsH = uicontrol('Parent', graphspanelH, 'Units', 'normalized', ...
    'Position', [0.03 0.65 0.45 0.28], 'FontSize', 12, 'String', 'Select ROI & Plot',...
    'Callback', @getROIstats, 'Enable','off');

plotTileStatsH = uicontrol('Parent', graphspanelH, 'Units', 'normalized', ...
    'Position', [0.53 0.65 0.45 0.28], 'FontSize', 12, 'String', 'Plot Tile Data',...
    'Callback', @plotTileStats, 'Enable','off'); 

previewStackH = uicontrol('Parent', graphspanelH, 'Units', 'normalized', ...
    'Position', [0.03 0.05 0.40 0.28], 'FontSize', 12, 'String', 'Preview Image Stack',...
    'Callback', @previewStack, 'Enable','off');
previewStacktxtH = uicontrol('Parent', graphspanelH, 'Style', 'Text', 'Units', 'normalized',...
    'Position', [0.45 0.29 0.15 0.13], 'FontSize', 11,'String', 'Frames');
previewStacknumH = uicontrol('Parent', graphspanelH, 'Style', 'Edit', 'Units', 'normalized', ...
    'Position', [0.45 0.09 0.15 0.20], 'FontSize', 13);
previewStackcbH = uicontrol('Parent', graphspanelH,'Style','checkbox','Units','normalized',...
    'Position', [.62 0.12 .14 .14] ,'String','', 'Value',1);
previewStacktxtH = uicontrol('Parent', graphspanelH, 'Style', 'Text', 'Units', 'normalized',...
    'Position', [.66 0.10 .28 .15], 'FontSize', 10,'String', 'Postprocessing Previews');


%----------------------------------------------------
%    CUSTOM FUNCTIONS PANEL
%----------------------------------------------------
customfunpanelH = uipanel('Title','Custom Code & Data Exploration','FontSize',10,...
    'BackgroundColor',[.95 .95 .95],...
    'Position', [0.80 0.64 0.18 0.34]); % 'Visible', 'Off',
              
runCustomAH = uicontrol('Parent', customfunpanelH, 'Units', 'normalized', ...
    'Position', [0.03 0.73 0.95 0.20], 'FontSize', 13, 'String', 'Custom Function A',...
    'Callback', @runCustomA);

runCustomBH = uicontrol('Parent', customfunpanelH, 'Units', 'normalized', ...
    'Position', [0.03 0.50 0.95 0.20], 'FontSize', 13, 'String', 'Custom Function B',...
    'Callback', @runCustomB);

runCustomCH = uicontrol('Parent', customfunpanelH, 'Units', 'normalized', ...
    'Position', [0.03 0.26 0.95 0.20], 'FontSize', 13, 'String', 'Custom Function C',...
    'Callback', @runCustomC);

runCustomDH = uicontrol('Parent', customfunpanelH, 'Units', 'normalized', ...
    'Position', [0.03 0.03 0.95 0.20], 'FontSize', 13, 'String', 'Custom Function D',...
    'Callback', @runCustomD);





%----------------------------------------------------
%    DATA EXPLORATION & API PANEL
%----------------------------------------------------
explorepanelH = uipanel('Title','Data Exploration & API','FontSize',10,...
    'BackgroundColor',[.95 .95 .95],...
    'Position', [0.80 0.25 0.18 0.34]); % 'Visible', 'Off',
              
openImageJH = uicontrol('Parent', explorepanelH, 'Units', 'normalized', ...
    'Position', [0.03 0.73 0.95 0.20], 'FontSize', 13, 'String', 'Open stack in ImageJ ',...
    'Callback', @openImageJ, 'Enable','off');

exploreAH = uicontrol('Parent', explorepanelH, 'Units', 'normalized', ...
    'Position', [0.03 0.50 0.95 0.20], 'FontSize', 13, 'String', 'Explore Data A',...
    'Callback', @exploreA, 'Enable','off');

exploreBH = uicontrol('Parent', explorepanelH, 'Units', 'normalized', ...
    'Position', [0.03 0.26 0.95 0.20], 'FontSize', 13, 'String', 'Explore Data B',...
    'Callback', @exploreB, 'Enable','off');

exploreCH = uicontrol('Parent', explorepanelH, 'Units', 'normalized', ...
    'Position', [0.03 0.03 0.95 0.20], 'FontSize', 13, 'String', 'Explore Data C',...
    'Callback', @exploreC, 'Enable','off');



%----------------------------------------------------
%    SAVE AND EXPORT DATA
%----------------------------------------------------
exportpanelH = uipanel('Title','I/O','FontSize',10,...
    'BackgroundColor',[.95 .95 .95],...
    'Position', [0.80 0.02 0.18 0.20]); % 'Visible', 'Off',
              
exportvarsH = uicontrol('Parent', exportpanelH, 'Units', 'normalized', ...
    'Position', [0.03 0.65 0.95 0.28], 'FontSize', 13, 'String', 'Export Vars to Workspace ',...
    'Callback', @exportvars);

savedatasetH = uicontrol('Parent', exportpanelH, 'Units', 'normalized', ...
    'Position', [0.03 0.34 0.95 0.28], 'FontSize', 13, 'String', 'Save Dataset',...
    'Callback', @savedataset);

loadmatdataH = uicontrol('Parent', exportpanelH, 'Units', 'normalized', ...
    'Position', [0.03 0.03 0.95 0.28], 'FontSize', 13, 'String', 'Load .mat Dataset',...
    'Callback', @loadmatdata);



% enableButtons




grinlenstoolbox()





% -----------------------------------------------------------------
%%                     GUI TOOLBOX FUNCTIONS
% -----------------------------------------------------------------


%----------------------------------------------------
%   INITIAL GRIN TOOLBOX FUNCTION TO POPULATE GUI
%----------------------------------------------------
function grinlenstoolbox(hObject, eventdata)
%Load file triggers uiresume; the initial menu is set to invisible. Prompts
%user for file to load, copies the datastack from the file; sets the image 
%windows to visible, and plots the images.


    set(initmenuh, 'Visible', 'Off');
    set(mainguih, 'Visible', 'On');
    
    %----------------------------------------------------
    %           SET USER-EDITABLE GUI VALUES
    %----------------------------------------------------
    imgLogo = imread('grinlogo.png');
    set(haxGRIN, 'XLim', [1 size(imgLogo,2)], 'YLim', [1 size(imgLogo,1)]);
    set(smoothimgnumH, 'String', num2str(smoothSD));
    set(cropimgnumH, 'String', num2str(cropAmount));
    set(alignCSFramesnumH, 'String', num2str(CSonsetDelay));
    set(dFoverFnumH, 'String', num2str(baselineTime));
    set(previewStacknumH, 'String', num2str(previewStacknum));
    
    % set(imgblocksnumH, 'String', num2str(blockSize));
    % Set radiobuttons
    % stimtypeh.SelectedObject = stimtypeh1; 
    % stimtype = stimtypeh.SelectedObject.String;
    %----------------------------------------------------
    
    
    
    
    %----------------------------------------------------
    %                   DRAW IMAGE
    %----------------------------------------------------

        axes(haxGRIN)
        colormap(haxGRIN,parula)
    phGRIN = imagesc(imgLogo , 'Parent', haxGRIN);
        pause(.1)

disp('Ready!')
end




%----------------------------------------------------
%        IMPORT IMAGE STACK MAIN FUNCTION
%----------------------------------------------------
function importimgstack(hObject, eventdata)
diary on
disp('GRIN LENS IMAGING TOOLBOX - ACQUIRING DATASET')

    if numel(imgfilename) > 1
        disp('image stack path was set manually')
    else
        [imgfilename, imgpathname] = uigetfile({'*.tif*'},...
        'Select image stack to import', thisfilepath);        
    end
    

    
    
    if numel(xlsfilename) > 1
        disp('xls data path was set manually')
    else
    
        if numel(imgfilename) == 16

            xlsFiles = dir([imgpathname, imgfilename(1:end-5) '*.xls*']);

        elseif numel(imgfilename) == 15

            xlsFiles = dir([imgpathname, imgfilename(1:end-4) '*.xls*']);

        end

        if numel(xlsFiles) == 1

            choice = questdlg({'Matching xls file found.', 'Would you like to import:',...
                               xlsFiles.name}, ...
                               'Import XLS file', ...
                               'Yes','No (import manually)','Yes');
            switch choice
                case 'Yes'
                    % disp([choice ' importing xls data...'])
                    xlsfilename = xlsFiles.name;
                    xlspathname = imgpathname;
                case 'No (import manually)'
                    [xlsfilename, xlspathname] = uigetfile({'*.xls*'},...
                    'Select Excel file associated with the TIF stack', imgpathname);
            end

        end
    
    end
    
    fprintf('\n\n GRIN DATASET: % s \n\n', imgfilename);
    
    
    % ------------- IMG STACK IMPORT CODE -----------
    grinano('import',[imgpathname , imgfilename])

    FileTif=[imgpathname , imgfilename];
    InfoImage=imfinfo(FileTif);
    mImage=InfoImage(1).Width;
    nImage=InfoImage(1).Height;
    NumberImages=length(InfoImage);
    
    IMG = zeros(nImage,mImage,NumberImages,'double');

    TifLink = Tiff(FileTif, 'r');
    for i=1:NumberImages
       TifLink.setDirectory(i);
       IMG(:,:,i)=TifLink.read();
    end
    TifLink.close();
    disp('Image stack sucessfully imported!') 
    
    axes(haxGRIN)
    colormap(haxGRIN,parula)
    phGRIN = imagesc(IMG(:,:,1) , 'Parent', haxGRIN);
              pause(1)
    
    IMGraw = IMG(:,:,1);
    % imgslider.Max = size(IMG);
    % imgsliderH.SliderStep = [1 size(IMG)]
              
              
              
    % ------------- XLS IMPORT CODE -----------
    grinano('importxls',[xlspathname , xlsfilename])

    [xlsN,xlsT,xlsR] = xlsread([xlspathname , xlsfilename]);
    
    if size(xlsN,1) == size(xlsR,1)
        xlsN(1,:) = [];
    end

    disp(' '); disp('Preview of raw xls import...')
    disp(xlsR(1:5,1:7))

    frame_period    = xlsN(1,1);
    framesUncomp    = xlsN(1,2);
    CS_type         = xlsT(2:end,3);
    US_type         = xlsT(2:end,4);
    delaytoCS       = xlsN(:,5);
    CS_length       = xlsN(1,6);
    compressFrms    = xlsN(1,7);

    total_trials    = size(xlsN,1);                     % total number of trials
    framesPerTrial  = framesUncomp / compressFrms;      % frames per trial
    secPerFrame     = frame_period * compressFrms;      % seconds per frame
    framesPerSec    = 1 / secPerFrame;                  % frames per second
    secondsPerTrial = framesPerTrial * secPerFrame;     % seconds per trial
    total_frames    = total_trials * framesPerTrial;    % total collected frames
    CS_lengthFrames = round(CS_length .* framesPerSec); % CS length in frames

    
    
    if isbrad
    lickFiles = dir([lickpathname, lickfilename(1:end-5) '*.xls*']);
    
    [lickN,~,~] = xlsread([lickpathname , lickFiles.name]);
    
    LICK = reshape(lickN,...
            floor(size(lickN,1) / framesPerTrial),...
            [],...
            size(lickN,2));
        
    % keyboard
        
    LICK = squeeze(sum(LICK,1));
                
        tv1 = [];
        tv2 = [];
        tv3 = [];
        tv4 = [];
        
    end
    
    
    disp('XLS data successfully imported and processed!')
    grinano('xlsparams',total_trials, framesPerTrial, secPerFrame, framesPerSec, secondsPerTrial)

    % CREATE ID FOR EACH UNIQUE CS+US COMBO AND DETERMINE ROW 
    [GRINstruct, GRINtable] = gettrialtypes(total_trials, CS_type, US_type, framesPerTrial);

    GRINstruct.file  = imgfilename;

    disp('GRINstruct contains the following structural arrays:')
    disp('{  Example usage: GRINstruct.tf(:,1)  }')
    disp(GRINstruct)

    disp('GRINtable includes the following columns:')
    disp(GRINtable(1:10,:))

    CSonsetDelay = min(delaytoCS);
    set(alignCSFramesnumH, 'String', num2str(CSonsetDelay));
    baselineTime = CSonsetDelay;
    set(dFoverFnumH, 'String', num2str(baselineTime));
        
     CSUSvals = unique(GRINstruct.csus);
     set(CSUSpopupH, 'String', CSUSvals);
     
     
     % VISUALIZE AND ANNOTATE
     fprintf('\n\n Imported stack size: % s ', num2str(size(IMG)));
     
  IMG = IMG(:,:,1:total_frames);
     
     fprintf('\n Size after excel-informed adjustment:  % s \n\n', num2str(size(IMG)));
     
     update_IMGfactors()
    
enableButtons
disp('Image stack and xls data import completed!')
diary(confile)
diary off
end




%----------------------------------------------------
%        FORMAT XLS DATASHEETS
%----------------------------------------------------
function formatXLS()
    
    msgbox('Coming Soon!'); 
   return
   
   xlsdata = formatXLS(varargin);
     
end




%----------------------------------------------------
%        ENABLE AND DISABLE GUI BUTTONS
%----------------------------------------------------
function enableButtons()

    smoothimgH.Enable = 'on';
    cropimgH.Enable = 'on';
    imgblocksH.Enable = 'on';
    dFoverFH.Enable = 'on';
    reshapeDataH.Enable = 'on';
    unshapeDataH.Enable = 'on';
    alignCSFramesH.Enable = 'on';
    timepointMeansH.Enable = 'on';
    getROIstatsH.Enable = 'on';
    plotTileStatsH.Enable = 'on';
    runallIPH.Enable = 'on';
    previewStackH.Enable = 'on';

    if numel(size(IMG)) > 1 && numel(size(IMG)) < 4;
        openImageJH.Enable = 'on';
    else
        openImageJH.Enable = 'off';
    end
end

function disableButtons()
    
    smoothimgH.Enable = 'off';
    cropimgH.Enable = 'off';
    imgblocksH.Enable = 'off';
    dFoverFH.Enable = 'off';
    reshapeDataH.Enable = 'off';
    unshapeDataH.Enable = 'off';
    alignCSFramesH.Enable = 'off';
    timepointMeansH.Enable = 'off';
    getROIstatsH.Enable = 'off';
    plotTileStatsH.Enable = 'off';
    runallIPH.Enable = 'off';
    openImageJH.Enable = 'off';
    previewStackH.Enable = 'off';

end







%----------------------------------------------------
%        CONSOLE DIARY ON / OFF / OPEN
%----------------------------------------------------
function conon
    diary on
end
function conoff
    diary(confile)
    diary off
    web(confilefullpath{1})
end



%----------------------------------------------------
%        CSUS DROPDOWN MENU CALLBACK
%----------------------------------------------------
function CSUSpopup(hObject, eventdata)

    if numel(GRINtable) > 0 
        disp('reminder of CS/US combos...')
        GRINtable(1:7,1:2)
        % GRINstruct
    end
        
    stimnum = CSUSpopupH.Value;

    % CSUSvals = unique(GRINstruct.csus);
    % set(CSUSpopupH, 'String', CSUSvals);

end




%----------------------------------------------------
%        RADIO BUTTON CALLBACK
%----------------------------------------------------
function stimselection(source,callbackdata)
        
    % strcmp(stimtypeh.SelectedObject.String,'CSxUS')
    stimtype = stimtypeh.SelectedObject.String;
    
    display(['Previous Stim: ' callbackdata.OldValue.String]);
    display(['Current Stim: ' callbackdata.NewValue.String]);
    display('------------------');
    
    
    % % RADIO BUTTON GROUP FOR TIMEPOINT MEANS
    % stimtypeh = uibuttongroup('Parent', IPpanelH, 'Visible','on',...
    %                   'Units', 'normalized',...
    %                   'Position',[0.63 0.31 0.35 0.06],...
    %                   'SelectionChangedFcn',@stimselection);              
    % stimtypeh1 = uicontrol(stimtypeh,'Style','radiobutton',...
    %                   'String','CSxUS',...
    %                   'Units', 'normalized',...
    %                   'Position',[0.04 0.05 0.38 0.9],...
    %                   'HandleVisibility','off');
    % stimtypeh2 = uicontrol(stimtypeh,'Style','radiobutton',...
    %                   'String','CS',...
    %                   'Units', 'normalized',...
    %                   'Position',[0.42 0.05 0.3 0.9],...
    %                   'HandleVisibility','off');
    % stimtypeh3 = uicontrol(stimtypeh,'Style','radiobutton',...
    %                   'String','US',...
    %                   'Units', 'normalized',...
    %                   'Position',[0.68 0.05 0.3 0.9],...
    %                   'HandleVisibility','off');

end
















%----------------------------------------------------
%        SMOOTH IMAGES
%----------------------------------------------------
function smoothimg(boxidselecth, eventdata)    
disableButtons; pause(.02);

    % PERFORM IMAGE SMOOTHING
    disp(' '); disp('PERFORMING IMAGE SMOOTHING')

    
    smoothSD = str2num(smoothimgnumH.String);
    % smoothHeight = .8;
    % smoothWidth = 9;
    % smoothSD = .16;
    % smoothRes = .1;
    

    % GRINmask([PEAK HEIGHT] [WIDTH] [SLOPE SD] [RESOLUTION] [doPLOT])
    % Mask = GRINkernel(.8, 9, .14, .1, 1);
    Mask = GRINkernel(smoothHeight, smoothWidth, smoothSD, smoothRes, 1);
    pause(.2)
    % IMGmsk = IMG(:,:,1);
    % IMGmsk(1:size(Mask),1:size(Mask)) = Mask;
    % figure; imagesc(IMGmsk);
    
    mbh = msgbox('Performing convolution smoothing, please wait...');
    IMGc = convn( IMG, Mask,'same');
    close(mbh);

        % VISUALIZE AND ANNOTATE
        fprintf('\n\n IMG matrix previous size: % s ', num2str(size(IMG)));
        fprintf('\n IMG matrix current size:  % s \n\n', num2str(size(IMGc)));
        % GRINcompare(IMG, IMGc, previewNframes)
        mainguih.HandleVisibility = 'off';
        close all;
        mainguih.HandleVisibility = 'on';
    
    IMG = IMGc;
    
        previewStack

        axes(haxGRIN)
        phGRIN = imagesc(IMG(:,:,1) , 'Parent', haxGRIN);


enableButtons        
disp('Image smoothing completed!')
end






%----------------------------------------------------
%        CROP IMAGES
%----------------------------------------------------
function cropimg(boxidselecth, eventdata)
disableButtons; pause(.02);

    % TRIM EDGES FROM IMAGE
    disp(' '); disp('TRIMMING EDGES FROM IMAGE')
    
    
    cropAmount = str2num(cropimgnumH.String);

    IMGt = IMG((cropAmount+1):(end-cropAmount) , (cropAmount+1):(end-cropAmount) , :);

        % VISUALIZE AND ANNOTATE
        grinano('trim',IMG,IMGt)
        % fprintf('\n\n IMG matrix previous size: % s ', num2str(size(IMG)));
        % fprintf('\n IMG matrix current size: % s \n\n', num2str(size(IMGt)));
        % GRINcompare(IMG, IMGt, previewNframes)
        mainguih.HandleVisibility = 'off';
        close all;
        mainguih.HandleVisibility = 'on';
    
    IMG = IMGt;
    
    IMGraw = IMGt(:,:,1);
    
        previewStack
        axes(haxGRIN)
        phGRIN = imagesc(IMG(:,:,1) , 'Parent', haxGRIN);

        update_IMGfactors()
        
enableButtons        
disp('Crop Images completed!')
end



















%----------------------------------------------------
%        IMGBLOCKS POPUP MENU CALLBACK
%----------------------------------------------------
function imgblockspopup(hObject, eventdata)
        
    blockSize = str2num(imgblockspopupH.String(imgblockspopupH.Value,:));
    
    fprintf('\n\n New tile size: % s \n\n', num2str(blockSize));
    
    % imgblockspopupH.String
    % imgblockspopupH.Value

end



%----------------------------------------------------
%  GET FACTORS THAT DIVIDE EVENLY INTO size(IMG,1)
%----------------------------------------------------
function update_IMGfactors()
    
    szIMG = size(IMG,1);
        
    s=1:szIMG;
    
    IMGfactors = s(rem(szIMG,s)==0);
    
    imgblockspopupH.String = IMGfactors;
    
    
    
    if any(IMGfactors == 22)
        
        imgblockspopupH.Value = find(IMGfactors==22);
        blockSize = str2num(imgblockspopupH.String(imgblockspopupH.Value,:));
        
    elseif numel(IMGfactors) > 2

        imgblockspopupH.Value = round(numel(IMGfactors)/2)+1;
        blockSize = str2num(imgblockspopupH.String(imgblockspopupH.Value,:));
        
    else
        
        imgblockspopupH.Value = ceil(numel(IMGfactors)/2);
        blockSize = str2num(imgblockspopupH.String(imgblockspopupH.Value,:));
    
    end

    % fprintf('\n\n New tile size: % s \n\n', num2str(blockSize));

end





%----------------------------------------------------
%        CREATE IMAGE TILES
%----------------------------------------------------
function imgblocks(boxidselecth, eventdata)
% disableButtons; pause(.02);

    % CREATE IMAGES TILES PER ROBERT'S SPEC
    disp('SEGMENTING IMGAGES INTO TILES')

    
    update_IMGfactors()
    blockSize = str2num(imgblockspopupH.String(imgblockspopupH.Value,:));
    
    fprintf('\n\n Tile Size: % s \n\n', num2str(blockSize));
        
    fun = @(block_struct) mean(block_struct.data(:)) * ones(size(block_struct.data)); 

    IMGb = zeros(size(IMG));

    sz = size(IMG,3);
    progresstimer('Segmenting images into blocks...')
    % hwb = waitbar(0,'Segmenting image into tiles...');
    for nn = 1:sz

        IMGb(:,:,nn) = blockproc(IMG(:,:,nn),[blockSize blockSize],fun);
        
        if ~mod(nn,100)
            % waitbar(nn/sz)
            progresstimer(nn/sz)
        end
    
    end
    
        % close(hwb)
        % VISUALIZE AND ANNOTATE
        fprintf('\n\n IMG matrix previous size: % s ', num2str(size(IMG)));
        fprintf('\n IMG matrix current size: % s \n\n', num2str(size(IMGb)));
        % GRINcompare(IMG, IMGb, previewNframes)
        mainguih.HandleVisibility = 'off';
        close all;
        mainguih.HandleVisibility = 'on';
    
    IMG = IMGb;
    
        previewStack
        axes(haxGRIN)
        phGRIN = imagesc(IMG(:,:,1) , 'Parent', haxGRIN);

        
enableButtons
disp('Block-Segment Images completed!')        
end









%----------------------------------------------------
%        RESHAPE DATA BY TRIALS
%----------------------------------------------------
function reshapeData(boxidselecth, eventdata)
disableButtons; pause(.02);

    % RESHAPE IMAGE STACK INTO SIZE: YPIXELS by XPIXELS in NFRAMES per NTRIALS
    disp(' '); disp('RESHAPING DATASET (ADDINING DIM FOR TRIALS)'); 
    
    IMGr = reshape(IMG,size(IMG,1),size(IMG,2),framesPerTrial,[]);
        
    
        % VISUALIZE AND ANNOTATE
        fprintf('\n\n IMG matrix previous size: % s ', num2str(size(IMG)));
        fprintf('\n IMG matrix current size: % s \n\n', num2str(size(IMGr)));
    
    IMG = IMGr;
        
        axes(haxGRIN)
        phGRIN = imagesc(IMG(:,:,1) , 'Parent', haxGRIN);


enableButtons
disp('Reshape stack by trial completed!')
end






%----------------------------------------------------
%        UNDO RESHAPE DATA
%----------------------------------------------------
function unshapeData(boxidselecth, eventdata)
disableButtons; pause(.02);

    % RESHAPE IMAGE STACK INTO SIZE: YPIXELS by XPIXELS in NTOTALFRAMES
    disp(' '); disp('UNDOING DATASET RESHAPE (REMOVING TRIALS DIM)'); 
    
    IMGr = reshape(IMG,size(IMG,1),size(IMG,2),[]);
        
    
        % VISUALIZE AND ANNOTATE
        fprintf('\n\n IMG matrix previous size: % s ', num2str(size(IMG)));
        fprintf('\n IMG matrix current size: % s \n\n', num2str(size(IMGr)));
    
    IMG = IMGr;
        
        axes(haxGRIN)
        phGRIN = imagesc(IMG(:,:,1) , 'Parent', haxGRIN);


enableButtons
disp('Undo reshape (make 3D) completed!')
end









%----------------------------------------------------
%        ALIGN CS FRAMES BY CS ONSET
%----------------------------------------------------
function alignCSframes(boxidselecth, eventdata)
disableButtons; pause(.02);

    % MAKE DELAY TO CS EQUAL TO t SECONDS FOR ALL TRIALS
    fprintf('\n\n MAKING CS DELAY EQUAL TO [ % s  ]SECONDS FOR ALL TRIALS'...
        , alignCSFramesnumH.String);

    % Make all CS onsets this many seconds from trial start
    CSonsetDelay = str2num(alignCSFramesnumH.String);
    


    EqualizeCSdelay  = round((delaytoCS-CSonsetDelay) .* framesPerSec);

    IMGe = IMG;
    for nn = 1:size(IMG,4)

        IMGe(:,:,:,nn) = circshift( IMGe(:,:,:,nn) , -EqualizeCSdelay(nn) ,3);

    end
    
    
    
    % DETERMINE FIRST AND LAST FRAME FOR CS / US FOR EACH TRIAL
    CSonset  = round(CSonsetDelay .* framesPerSec);                % CS first frame in trial
    CSoffset  = round((CSonsetDelay+CS_length) .* framesPerSec);   % CS last frame in trial
    USonset  = round((CSonsetDelay+CS_length+1) .* framesPerSec);  % US first frame in trial
    USoffset  = round((CSonsetDelay+CS_length+2) .* framesPerSec); % US last frame in trial
    CSUSonoff = [CSonset CSoffset USonset USoffset];
    
    GRINstruct.CSUSonoff = CSUSonoff;
    
    fprintf(['\n\n (in frames)...\n   CSon: % 6.1d \n   CSoff: % 5.1d ',...
             '\n   USon: % 6.1d \n   USoff: % 5.1d '],CSUSonoff);
    
    
        % VISUALIZE AND ANNOTATE
        fprintf('\n\n IMG matrix previous size: % s ', num2str(size(IMG)));
        fprintf('\n IMG matrix current size: % s \n\n', num2str(size(IMGe)));
    
    IMG = IMGe;
    
        axes(haxGRIN)
        phGRIN = imagesc(IMG(:,:,1) , 'Parent', haxGRIN);

        
enableButtons
disp('Align frames by CS onset completed!')
end










%----------------------------------------------------
%        deltaF OVER F
%----------------------------------------------------
function dFoverF(boxidselecth, eventdata)
disableButtons; pause(.02);

    % COMPUTE dF/F FOR ALL FRAMES
    disp(' '); disp('COMPUTING dF/F FOR ALL FRAMES')
    
    
    if numel(size(IMG)) == 3
        
        % As a shortcut and to retain the original frame number I am using
        % circshift to move the first image to the end of the image matrix
        im = circshift( IMG , -1 ,3);
        IMGf = (im - IMG) ./ im;
        IMGf(:,:,end) = IMGf(:,:,end-1); % this just duplicates the last frame
    
        % muIMG = mean(IMG(:,:,1:baselineTime),3);
        % im = repmat(muIMG,1,1,size(IMG,3));
        % IMGf = (IMG - im) ./ im;
    
    elseif numel(size(IMG)) == 4
        
        muIMG = mean(IMG(:,:,1:baselineTime,:),3);
        im = repmat(muIMG,1,1,size(IMG,3));
        IMGf = (IMG - im) ./ im;
        
    end

    
    
    
        % VISUALIZE AND ANNOTATE
        fprintf('\n\n IMG matrix previous size: % s ', num2str(size(IMG)));
        fprintf('\n IMG matrix current size: % s \n\n', num2str(size(IMGf)));
        % GRINcompare(IMG, IMGf, previewNframes, [.98 1.05], [8 2])
        mainguih.HandleVisibility = 'off';
        close all;
        mainguih.HandleVisibility = 'on';
    
    IMG = IMGf;
    
        previewStack
        axes(haxGRIN)
        phGRIN = imagesc(IMG(:,:,1) , 'Parent', haxGRIN);

        
enableButtons        
disp('dF/F computation completed!')
end










%----------------------------------------------------
%        GET TIMEPOINT MEANS
%----------------------------------------------------
function timepointMeans(boxidselecth, eventdata)
disableButtons; pause(.02);    
    
    disp(' '); disp('COMPUTING TRIAL MEANS (AVERAGING SAME-TIMEPOINTS ACROSS TRIALS)'); 
    
    % AVERAGE ACROSS SAME TIMEPOINTS
    nCSUS = size(GRINstruct.tf,2);
    szIMG = size(IMG);
    
    % Check that input is 4D
    if numel(szIMG) ~= 4
        ms = {'Stack must be 4D to compute timepoint means',...
              ['Stack is currently: ' num2str(szIMG)]};
        msgbox(ms, 'invalid stack size','custom',imgLogo(80:140,60:120,:));
        return
    end
    
    
    
    % Perform averaging for each (nCSUS) unique trial type
    % This will create a matrix 'muIMGS' of size [h,w,f,nCSUS]
    muIMGS = zeros(szIMG(1), szIMG(2), szIMG(3), nCSUS);
    for tt = 1:nCSUS
        im = IMG(:,:,:,GRINstruct.tf(:,tt));
        muIMGS(:,:,:,tt) = squeeze(mean(im,4));
    end


    
        % VISUALIZE AND ANNOTATE
        fprintf('\n\n IMG matrix retains size: % s ', num2str(size(IMG)));
        fprintf('\n muIMGS matrix is now size: % s \n\n', num2str(size(muIMGS)));
        GRINcompare(IMG, muIMGS, previewNframes)
        mainguih.HandleVisibility = 'off';
        close all;
        mainguih.HandleVisibility = 'on';
        disp('Done!')
    
    % IMG = IMGf;
    
        axes(haxGRIN)
        phGRIN = imagesc(muIMGS(:,:,1,1) , 'Parent', haxGRIN);

enableButtons        
disp('Compute same-timepoint means completed!')
end







%----------------------------------------------------
%        GET ROI STATISTICS
%----------------------------------------------------
function getROIstats(boxidselecth, eventdata)
disableButtons; pause(.02);
    
    % PREVIEW AN ROI FOR A SINGLE CSUS AVERAGED OVER TRIALS
    disp(' '); disp('GETTING ROI STATISTICS'); 

    fh1=figure('Units','normalized','OuterPosition',[.40 .22 .59 .75],'Color','w');
    hax1 = axes('Position',[.05 .05 .9 .9],'Color','none','XTick',[]);

    ih1 = imagesc(muIMGS(:,:,1,1));

    disp('Use mouse to trace around a region of interest on the figure.')
    hROI = imfreehand(hax1);   
    ROIpos = hROI.getPosition;
    ROIarea = polyarea(ROIpos(:,1),ROIpos(:,2));


    ROImask = hROI.createMask(ih1);
    
    ROI_INTENSITY = muIMGS(:,:,1,1) .* ROImask;
    figure; imagesc(ROI_INTENSITY); colorbar;




    % Here we are computing the average intensity for the selected ROI
    % N.B. here it is assumed that a pixel value (actually dF/F value)
    % has virtually a zero probability of equaling exactly zero; this
    % allows us to multiply the mask T/F matrix by the image matrix
    % and disclude from the average all pixels that equal exactly zero
    
    ROImu = zeros(size(muIMGS,4),size(muIMGS,3));
    for mm = 1:size(muIMGS,4)
        for nn = 1:size(muIMGS,3)
        
        ROI_INTENSITY = muIMGS(:,:,nn,mm) .* ROImask;
        ROImu(mm,nn) = mean(ROI_INTENSITY(ROI_INTENSITY ~= 0));

        end
    end

    CSUSplot(ROImu', GRINstruct);
    % CSUSplot(ROImu', GRINstruct, CSUSonoff);
    % previewstack(squeeze(muIMGS(:,:,:,1)), CSUSonoff, ROImu)
    
    
    
    
enableButtons
disp('Compute ROI statistics completed!')
end








%----------------------------------------------------
%        PLOT TILE STATS DATA
%----------------------------------------------------
function plotTileStats(boxidselecth, eventdata)
% disableButtons; pause(.02);

    disp(' '); disp('PLOTTING TILE STATS DATA (PLEASE WAIT)...'); 
    
    % EVENTUALLY REPLACE YLIMS WITH...
    % [IMGcMax, IMGcMaxInd] = max(IMG(:));
    % [IMGcMin, IMGcMinInd] = min(IMG(:)); 
    
    fh1=figure('Units','normalized','OuterPosition',[.08 .08 .8 .8],'Color','w');
    hax1 = axes('Position',[.05 .05 .9 .9],'Color','none');
    hax1.YLim = [-.15 .15];
    hax2 = axes('Position',[.05 .05 .9 .9],'Color','none');
    hax2.YLim = [-.15 .15];
    axis off; hold on;
    hax3 = axes('Position',[.05 .05 .9 .9],'Color','none');
    hax3.YLim = [-.15 .15];
    axis off; hold on;
    hax4 = axes('Position',[.05 .05 .9 .9],'Color','none');
    hax4.YLim = [-.15 .15];
    axis off; hold on;
    hax5 = axes('Position',[.05 .05 .9 .9],'Color','none');
    hax5.YLim = [-.15 .15];
    axis off; hold on;
    hax6 = axes('Position',[.05 .05 .9 .9],'Color','none');
    hax6.YLim = [-.15 .15];
    axis off; hold on;
    hax0 = axes('Position',[.05 .05 .9 .9],'Color','none');
    hax0.YLim = [-.15 .15];
    axis off; hold on;
    allhax = {hax1, hax2, hax3, hax4, hax5, hax6};
    colorz = {  [.99 .01 .01], ...
                [.01 .99 .01], ...
                [.01 .01 .99], ...
                [.99 .01 .99], ...
                [.99 .99 .01], ...
                [.01 .99 .99], ...
                };
    legpos = {  [0.75,0.85,0.15,0.06], ...
                [0.75,0.80,0.15,0.06], ...
                [0.75,0.75,0.15,0.06], ...
                [0.75,0.70,0.15,0.06], ...
                [0.75,0.65,0.15,0.06], ...
                [0.75,0.60,0.15,0.06], ...
                };

    
    
    blockSize = str2num(imgblockspopupH.String(imgblockspopupH.Value,:));

    pxl = muIMGS(1:blockSize:end,1:blockSize:end,:,:);

    pixels = squeeze(reshape(pxl,numel(pxl(:,:,1)),[],size(pxl,3),size(pxl,4)));
    
    CSids = unique(GRINstruct.csus);
    
    %==============================================%
    for nn = 1:size(pixels,3)
    
    pixCS = pixels(:,:,nn);
	
	Mu = mean(pixCS,1);
    Sd = std(pixCS,0,1);
    Se = Sd./sqrt(numel(Mu));
	y_Mu = Mu';
    x_Mu = (1:numel(Mu))';
    % e_Mu = Se';
    e_Mu = Sd';
	xx_Mu = 1:0.1:max(x_Mu);
	yy_Mu = spline(x_Mu,y_Mu,xx_Mu);
    ee_Mu = spline(x_Mu,e_Mu,xx_Mu);
    

    axes(allhax{nn})
    [ph1, po1] = envlineplot(xx_Mu',yy_Mu', ee_Mu','cmap',colorz{nn},...
                            'alpha','transparency', 0.6);
    hp1{nn} = plot(xx_Mu,yy_Mu,'Color',colorz{nn});
    pause(.2)
    
    % lh1{nn} = legend(allhax{nn},CSids(nn),'Position',legpos{nn},'Box','off');
    
    end
    %==============================================%
    
    text(1, -.12, ['CS ON/OFF US ON/OFF:  ', num2str(CSUSonoff)])
    
    
    leg1 = legend([hp1{:}],CSids);
	set(leg1, 'Location','NorthWest', 'Color', [1 1 1],'FontSize',12,'Box','off');
    set(leg1, 'Position', leg1.Position .* [1 .94 1 1.4])
    
        
    for mm = 1:4
    text(CSUSonoff(mm),allhax{nn}.YLim(1),{'\downarrow'},...
        'HorizontalAlignment','center','VerticalAlignment','bottom',...
        'FontSize',20,'FontWeight','bold')
    end
    line([CSUSonoff(1) CSUSonoff(1)],[allhax{nn}.YLim(1) allhax{nn}.YLim(2)])
    line([CSUSonoff(2) CSUSonoff(2)],[allhax{nn}.YLim(1) allhax{nn}.YLim(2)])
    %==============================================%
    pause(.1)
    

fh10=figure('Units','normalized','OuterPosition',[.02 .02 .90 .90],'Color','w');

    aXlocs =  (0:(size(pxl,1))) .* (1/(size(pxl,1)));
    aXlocs(end) = [];
    aYlocs =  (0:(size(pxl,2))) .* (1/(size(pxl,2)));
    aYlocs(end) = [];
    aXlocs = aXlocs+.005;
    aYlocs = aYlocs+.005;
    [aX,aY] = meshgrid(aXlocs,aYlocs);
    YL=[-.15 .15];
    
    %{
%     for tt = 1:size(pixels,3)
%         for ii = 1:size(pixels,1)
%                 
%         
%         axes('Position',[aX(ii) aY(ii) (1/(size(pxl,1)+1)) (1/(size(pxl,2)+1))],...
%         'Color','none'); axis off; hold on;
%     
%         plot( 1:size(pixels,2) , pixels(ii,:,tt) ,'Color',colorz{tt})
%         set(gca,'YLim',YL)
%         line([CSUSonoff(1) CSUSonoff(1)],YL,'Color',[.8 .8 .8])
%         line([CSUSonoff(2) CSUSonoff(2)],YL,'Color',[.8 .8 .8])
%                     
%         end
%         pause(.05)
%     end
%}

    for ii = 1:size(pixels,1)

        axes('Position',[aX(ii) aY(ii) (1/(size(pxl,1)+1)) (1/(size(pxl,2)+1))],...
        'Color','none'); axis off; hold on;
    
        % h = squeeze(pixels(ii,:,:));
        pha = plot( 1:size(pixels,2) , squeeze(pixels(ii,:,:)));
        set(gca,'YLim',YL)
        line([CSUSonoff(1) CSUSonoff(1)],YL,'Color',[.8 .8 .8])
        line([CSUSonoff(2) CSUSonoff(2)],YL,'Color',[.8 .8 .8])
                    
    end
        pause(.05)
    
    
    
    
    legpos = {  [0.01,0.94,0.15,0.033], ...
                [0.01,0.90,0.15,0.033], ...
                [0.01,0.86,0.15,0.033], ...
                [0.01,0.82,0.15,0.033], ...
                [0.01,0.78,0.15,0.033], ...
                [0.01,0.74,0.15,0.033], ...
                };
    
    pc = {pha.Color};
    pt = CSids;
    
    for nn = 1:size(pixels,3)
        
    annotation(fh10,'textbox',...
    'Position',legpos{nn},...
    'Color',pc{nn},...
    'FontWeight','bold',...
    'String',pt(nn),...
    'FontSize',14,...
    'FitBoxToText','on',...
    'EdgeColor',pc{nn},...
    'FaceAlpha',.7,...
    'Margin',3,...
    'LineWidth',2,...
    'VerticalAlignment','bottom',...
    'BackgroundColor',[1 1 1]);
    
    end
    
%     % Add 'doprint' checkbox before implementing this code
%     print(fh10,'-dpng','-r300','tilefig')
%     
%     hFig = figure('Toolbar','none',...
%               'Menubar','none');
%     hIm = imshow('tilefig.png');
%     hSP = imscrollpanel(hFig,hIm);
%     set(hSP,'Units','normalized',...
%         'Position',[0 .1 1 .9])
   
    fhR = figure('Units','normalized','OuterPosition',[.1 .1 .5 .8],'Color','w');
    axR = axes;
    phR = imagesc(IMGraw);
    grid on
    axR.YTick = [0:blockSize:size(IMGraw,1)];
    axR.XTick = [0:blockSize:size(IMGraw,1)];
    % axR.YTickLabel = 1:30;
    
    axR.GridAlpha = .8;
    axR.GridColor = [0.99 0.1 0.1];
    
        tv1 = 1:size(IMGraw,1);
        
        pause(.2)
        
        for ii = 1:size(pixels,1)
            
            tv2 = [  aX(ii)*size(IMGraw,1)   aY(ii)*size(IMGraw,1)+2 ...
                    (1/(size(pxl,1)+1))     (1/(size(pxl,2)+1))];

            text(tv2(1),tv2(2),num2str(tv1(ii)),'Color','r','Parent',axR);
    
        end
    
enableButtons
disp('PLOTTING TILE STATS DATA COMPLETED!')
end









%----------------------------------------------------
%        RUN ALL IMAGE PROCESSING FUNCTIONS
%----------------------------------------------------
function runallIP(boxidselecth, eventdata)
disableButtons; pause(.02);
conon
        

    if checkbox1H.Value
        smoothimg
    end
    
    if checkbox2H.Value
        cropimg
    end
    
    if checkbox3H.Value
        imgblocks
    end

    if checkbox4H.Value
        reshapeData
    end

    if checkbox5H.Value
        alignCSframes
    end

    if checkbox6H.Value
        dFoverF
    end

    if checkbox7H.Value
        timepointMeans
    end


    
disp('PROCESSING COMPLETED - ALL SELECTED FUNCTIONS FINISHED RUNNING!')
conoff
enableButtons        
end













%----------------------------------------------------
%        PREVIEW IMAGE STACK
%----------------------------------------------------
function previewStack(boxidselecth, eventdata)
disableButtons; pause(.02);

    % disp('PREVIEWING IMAGE STACK')
    
    totframes = size(IMG,3);
    
    previewStacknum = str2num(previewStacknumH.String);

    
    if totframes >= previewStacknum
    
        IMGi = IMG(:,:,1:previewStacknum);
    
    
        [IMGcMax, IMGcMaxInd] = max(IMG(:));
        [IMGcMin, IMGcMinInd] = min(IMG(:));    
        % [I,J,tmp1] = ind2sub(size(IMG),cb1)
        % IMG(I,J,tmp1)

        axes(haxGRIN)
        phGRIN = imagesc(IMG(:,:,1) , 'Parent', haxGRIN);


        for nn = 1:previewStacknum

            phGRIN.CData = IMGi(:,:,nn);

            pause(.04)
        end
    
    

        % VISUALIZE AND ANNOTATE
        % fprintf('\n\n IMG matrix previous size: % s ', num2str(size(IMG)));
        % fprintf('\n IMG matrix current size: % s \n\n', num2str(size(IMGt)));
        % GRINcompare(IMG, IMGt, previewNframes)
        % mainguih.HandleVisibility = 'off';
        % close all;
        % mainguih.HandleVisibility = 'on';
    
    
    else
        
       disp('Not enough images in 3rd dim to preview that many frames') 
        
    end

        
enableButtons        
% disp('Preview completed!')
end







%----------------------------------------------------
%        RUN CUSTOM FUNCTION
%----------------------------------------------------
function runCustomA(boxidselecth, eventdata)
% disableButtons; pause(.02);

    disp('RUNNING YOUR CUSTOM FUNCTION!')
        
    grincustomA(IMG, GRINstruct, GRINtable)
    
enableButtons        
disp('Run custom function completed!')
end

function runCustomB(boxidselecth, eventdata)
% disableButtons; pause(.02);

    disp('RUNNING YOUR CUSTOM FUNCTION!')
        
    grincustomB(IMG, GRINstruct, GRINtable)
    
enableButtons        
disp('Run custom function completed!')
end

function runCustomC(boxidselecth, eventdata)
% disableButtons; pause(.02);

    disp('RUNNING YOUR CUSTOM FUNCTION!')
            
    grincustomC(IMG, GRINstruct, GRINtable)
    
enableButtons        
disp('Run custom function completed!')
end

function runCustomD(boxidselecth, eventdata)
% disableButtons; pause(.02);

    disp('RUNNING YOUR CUSTOM FUNCTION!')
    
    mainguih.HandleVisibility = 'off';
    close all;
    mainguih.HandleVisibility = 'on';
        
    grincustomD(IMG, GRINstruct, GRINtable)
    
enableButtons        
disp('Run custom function completed!')
end



%----------------------------------------------------
%        EXPORT DATA TO BASE WORKSPACE
%----------------------------------------------------
function exportvars(boxidselecth, eventdata)
% disableButtons; pause(.02);

    if size(GRINtable,1) > 1
        checkLabels = {'Save IMG to variable named:' ...
                   'Save GRINstruct to variable named:' ...
                   'Save GRINtable to variable named:'}; 
        varNames = {'IMG','GRINstruct','GRINtable'}; 
        items = {IMG,GRINstruct,GRINtable};
        export2wsdlg(checkLabels,varNames,items,...
                     'Save Variables to Workspace');

        disp('Main VARS exported to base workspace')
    else
        disp('no variables available to export')
    end
    
enableButtons        
end


%----------------------------------------------------
%        SAVE DATA TO .MAT FILE
%----------------------------------------------------
function savedataset(boxidselecth, eventdata)
% disableButtons; pause(.02);

    if size(IMG,3) > 1
        
        
        [filen,pathn] = uiputfile([GRINstruct.file(1:end-4),'.mat'],'Save Vars to Workspace');
            
        if isequal(filen,0) || isequal(pathn,0)
           disp('User selected Cancel')
        else
           disp(['User selected ',fullfile(pathn,filen)])
        end
        
        % IMGint16 = uint16(IMG);
                
        disp('Saving data to .mat file, please wait...')
        save(fullfile(pathn,filen),'IMG','GRINstruct','GRINtable','-v7.3')
        % save(fullfile(pathn,filen),'IMGint16','GRINstruct','GRINtable','-v7.3')
        disp('Dataset saved!')
        
        % whos('-file','newstruct.mat')
        % m = matfile(filename,'Writable',isWritable)
        % save(filename,variables,'-append')

    else
        disp('No data to save')
    end
    
enableButtons        
end




%----------------------------------------------------
%        LOAD .mat DATA
%----------------------------------------------------
function loadmatdata(boxidselecth, eventdata)
% disableButtons; pause(.02);

    [filename, pathname] = uigetfile( ...
    {'*.mat',...
   '*.mat','MAT-files (*.mat)'}, ...
   'Select a .mat datafile');
    
    load([pathname, filename])


disp('Dataset loaded!')
enableButtons        
end






%----------------------------------------------------
%        OPEN IMAGEJ API
%----------------------------------------------------
function openImageJ(boxidselecth, eventdata)
disableButtons; pause(.02);

    % TRIM EDGES FROM IMAGE
    disp('LAUNCHING ImageJ!')
    
    % tifimg = IMG;
    matfiji(IMG)
        

    
%{    
% ----------------------------------------
    [str,maxsize,endian] = computer;


if strcmp(str,'PCWIN') || strcmp(str,'PCWIN64')
    
    javaaddpath 'C:\Program Files\MATLAB\R2014b\java\jar\mij.jar'
    javaaddpath 'C:\Program Files\MATLAB\R2014b\java\jar\ij.jar'
    MIJ.start('E:\Program Files (x86)\ImageJ')
    MIJ.setupExt('E:\Program Files (x86)\ImageJ');


    % strr1=strcat('open=[Y:\\ShareData\\LABMEETINGS\\Steve\\GRIN lens data\\RM\\*.tif] starting=1 increment=1 scale=100 file=Ch2 or=[] sort');
    % MIJ.run('Image Sequence...', strr1); %works!! will generate tif stack in imageJ

    MIJ.createImage('result', IMG, true);
    
end


if strcmp(str,'MACI64')
    
    javaaddpath '/Applications/MATLAB_R2014b.app/java/jar/mij.jar';
    javaaddpath '/Applications/MATLAB_R2014b.app/java/jar/ij.jar';
    MIJ.start('/Applications/Fiji');
    MIJ.setupExt('/Applications/Fiji');
    
    % strr1=strcat('open=[/Users/bradleymonk/Documents/MATLAB/myToolbox/LAB/grin/gcdata/031016_gc33_green_keep.tif]');
    % MIJ.run('Image Sequence...', strr1); %works!! will generate tif stack in imageJ
    
    MIJ.createImage('result', IMG, true);
    
end
% ----------------------------------------    
%}    
    
    
GRINtoolboxGUI    
return
enableButtons        
disp('ImageJ (FIJI) processes completed!')
end


%----------------------------------------------------
%        DATA EXPLORATION FUNCTIONS
%----------------------------------------------------
function exploreA(boxidselecth, eventdata)
% disableButtons; pause(.02);

    disp('RUNNING DATA EXPLORER A!')
    disp('COMING SOON!')
    
    
enableButtons        
disp('Data explorer function completed!')
end

function exploreB(boxidselecth, eventdata)
% disableButtons; pause(.02);

    disp('RUNNING DATA EXPLORER B!')
    disp('COMING SOON!')
    
    
enableButtons        
disp('Data explorer function completed!')
end

function exploreC(boxidselecth, eventdata)
% disableButtons; pause(.02);

    disp('RUNNING DATA EXPLORER C!')
    disp('COMING SOON!')
    
    
enableButtons        
disp('Data explorer function completed!')
end






%----------------------------------------------------
%        IMAGE SIDER CALLBACK
%----------------------------------------------------
function imgslider(hObject, eventdata)

% Hints: hObject.Value returns position of slider
%        hObject.Min and hObject.Max determine range of slider
% sunel = get(handles.sunelslider,'value'); % Get current light elev.
% sunaz = get(hObject,'value');   % Varies from -180 -> 0 deg

slideVal = ceil(imgsliderH.Value);

if size(IMG,3) > 99

    phGRIN = imagesc(IMG(:,:,slideVal) , 'Parent', haxGRIN);
              pause(.05)

    disp(['image' num2str(slideVal)])
    
else
    
    disp('There must be at least 100 images in the stack')
    disp('(per trial) to use the slider; currently there are')
    disp(size(IMG,3))

end

end





%----------------------------------------------------
%        MOTION CORRECTION
%----------------------------------------------------

function motioncorrection(hObject, eventdata)
   msgbox('Coming Soon!'); 
   return
   
    % clc; clear all; close all;

    % Input video file which needs to be stabilized.
    % filename = 'shaky_car.avi';
    filename = 'GRIN_zstack.avi';

    hVideoSource = vision.VideoFileReader(filename, ...
              'ImageColorSpace', 'Intensity','VideoOutputDataType', 'double');


    % Create geometric translator object used to compensate for movement.
    hTranslate = vision.GeometricTranslator( ...
           'OutputSize', 'Same as input image', 'OffsetSource', 'Input port');


    % Create template matcher object to compute location of best target match
    % in frame. Use location to find translation between successive frames.
    hTM = vision.TemplateMatcher('ROIInputPort', true, ...
                                'BestMatchNeighborhoodOutputPort', true);


    % Create object to display the original video and the stabilized video.
    hVideoOut = vision.VideoPlayer('Name', 'Video Stabilization');
    hVideoOut.Position(1) = round(0.4*hVideoOut.Position(1));
    hVideoOut.Position(2) = round(1.5*(hVideoOut.Position(2)));
    hVideoOut.Position(3:4) = [900 550];


        imgA = step(hVideoSource); % Read first frame into imgA
        figure
        imagesc(imgA);
        title('USE MOUSE TO DRAW BOX AROUND BEST STABILIZATION OBJECT')
        h1 = imrect;
        pos1 = round(getPosition(h1)); % [xmin ymin width height]


    % Here we initialize some variables used in the processing loop.

    pos.template_orig = [pos1(1) pos1(2)]; % [x y] upper left corner
    pos.template_size = [pos1(3:4)];    % [width height]
    pos.search_border = [10 10];        % max horizontal and vertical displacement

    pos.template_center = floor((pos.template_size-1)/2);
    pos.template_center_pos = (pos.template_orig + pos.template_center - 1);
    fileInfo = info(hVideoSource);
    W = fileInfo.VideoSize(1); % Width in pixels
    H = fileInfo.VideoSize(2); % Height in pixels
    BorderCols = [1:pos.search_border(1)+4 W-pos.search_border(1)+4:W];
    BorderRows = [1:pos.search_border(2)+4 H-pos.search_border(2)+4:H];
    sz = fileInfo.VideoSize;
    TargetRowIndices = ...
      pos.template_orig(2)-1:pos.template_orig(2)+pos.template_size(2)-2;
    TargetColIndices = ...
      pos.template_orig(1)-1:pos.template_orig(1)+pos.template_size(1)-2;
    SearchRegion = pos.template_orig - pos.search_border - 1;
    Offset = [0 0];
    Target = zeros(20,20);
    % Target = zeros(18,22);
    firstTime = true;



    % Stream Processing Loop

    % Processing loop using objects created above to perform stabilization
    nn = 0;
    while ~isDone(hVideoSource)
    nn = nn+1;

        input = step(hVideoSource);

        % Find location of Target in the input video frame
        if firstTime
          Idx = int32(pos.template_center_pos);
          MotionVector = [0 0];
          firstTime = false;
        else
          IdxPrev = Idx;

          ROI = [SearchRegion, pos.template_size+2*pos.search_border];
          Idx = step(hTM, input, Target, ROI);

          MotionVector = double(Idx-IdxPrev);
        end

        [Offset, SearchRegion] = updatesearch(sz, MotionVector, ...
            SearchRegion, Offset, pos);

        % Translate video frame to offset the camera motion
        Stabilized = step(hTranslate, input, fliplr(Offset));

        Target = Stabilized(TargetRowIndices, TargetColIndices);

        % Add black border for display
        Stabilized(:, BorderCols) = minmin;
        Stabilized(BorderRows, :) = minmin;

        TargetRect = [pos.template_orig-Offset, pos.template_size];
        SearchRegionRect = [SearchRegion, pos.template_size + 2*pos.search_border];

        % Draw rectangles on input to show target and search region
        input = insertShape(input, 'Rectangle', [TargetRect; SearchRegionRect],...
                            'Color', 'white');
        % Display the offset (displacement) values on the input image
        txt = sprintf('(%+05.1f,%+05.1f)', Offset);
        input = insertText(input(:,:,1),[191 215],txt,'FontSize',16, ...
                        'TextColor', 'white', 'BoxOpacity', 0);
        % Display video
        step(hVideoOut, [input(:,:,1) Stabilized]);


        sGRINs{nn} = Stabilized;
    end

    % Release hVideoSource
    release(hVideoSource);
    % ===============================================
   
end






% CREATE VISUAL IMAGE OF TRIAL BLOCKS AND CS / US ONSET / OFFSET
%{

trials = zeros(30,69);

y = randsample(30,15)

t = 1:30;
t(y) = 0;
z = find(t)

trials(y,25:35) = 1;
trials(y,36) = 0;
trials(y,37:47) = 3;

trials(z,35:45) = 2;
trials(z,46) = 0;
trials(z,47:57) = 4;




cm = [ 1  1  1
      .9 .1 .1
      .95 .2 .4
      .1 .9 .1
      .1 .95 .6
      ];

close all
fh1=figure('Units','normalized','OuterPosition',[.1 .1 .8 .6],'Color','w');
ih = imagesc(trials);
colormap(cm)
grid on
ax = gca;
ax.YTick = [.5:1:29.5];
ax.YTickLabel = 1:30;

%}


end
%% EOF