%Search for EEGLAB folder
locateEeglab = which('eeglab.m');
eeglabFolder = erase(locateEeglab, 'eeglab.m');

%Determine which system Matlab runs on
strSystem = computer;

%System-specific appendix to point Matlab to the functions used in this script.
strVerify = strfind(strSystem,'PCWIN');

if isempty(locateEeglab)
    %Point to functions used in this sript
    functionsEEGLAB = uigetdir(matlabroot,'Point to the folder >>functions<< of EEGLAB');

    if isempty(strVerify)
        addpath(strcat(functionsEEGLAB, '/', 'adminfunc', '/'));
        addpath(strcat(functionsEEGLAB, '/', 'popfunc', '/'));
    else
        addpath(strcat(functionsEEGLAB, '\', 'adminfunc', '\'));
        addpath(strcat(functionsEEGLAB, '\', 'popfunc','\'));
    end
else
    if isempty(strVerify)
        addpath(strcat(eeglabFolder, 'functions/popfunc/'));
        addpath(strcat(eeglabFolder, 'functions/adminfunc/'));
    else
        addpath(strcat(eeglabFolder, 'functions\popfunc\'));
        addpath(strcat(eeglabFolder, 'functions\adminfunc\'));
    end
end

%Give here the source folder of the .set files to be run ICA with
[FilesList, pathName, filterIndex] = uigetfile('*.set',...
   'Select one or more .set files.', ...
   'MultiSelect', 'on');

%if >1 files selected FilesList is a cell array, if 1 file only, then FilesList is a char --> transform to cell array
if ischar(FilesList)
    FilesList = {FilesList};
end

%Creates ICAWeights folder if does not exist. This is essential for saving
%the datasets later
existsICAWeights = exist ([pathName, 'ICAWeights'], 'dir');

if existsICAWeights ~= 7
    mkdir (pathName, 'ICAWeights');
end

conservedCharacters = strlength(inputdlg({'Delete parts of file name that are not part of base name structure (Delete last underscore if there)'},...
    'Base name structure', 1, FilesList(1,1)));

for Filenum = 1:numel(FilesList) %Loop going from the 1st element in the folder, to the total elements

    %Function to get the file name
    fileNameComplete = char(FilesList(Filenum));
    fileName = fileNameComplete(1:conservedCharacters);

    %Append ICAWeights to file names and set path for future save to
    %"daughter folder" ICAClean
    newFileName = strcat(fileName, '_ICAWeights.set');

    if isempty(strVerify)
        newFilePath = strcat(pathName, 'ICAWeights/');
    else
        newFilePath = strcat(pathName, 'ICAWeights\');
    end

    %Check if dataset has already been run ICA on
    existsFile = exist ([newFilePath, newFileName], 'file');

    if existsFile ~= 2
        
        ALLCOM = {};
        ALLEEG = [];
        CURRENTSET = 0;
        EEG = [];
        [ALLCOM ALLEEG EEG CURRENTSET] = eeglab;
        
        %Function to load .set into EEGLAB
        EEG = pop_loadset('filename',fileNameComplete,'filepath',pathName);

        %Don't know what this is doing, but I guess it is saving the opened
        %dataset in current and a global dataset
        [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );
        EEG = eeg_checkset( EEG );

        %Look if dataset contains Trigger channel
        searchTrigger = strfind(strcat(EEG.chanlocs.labels), 'Trigger');

        if isempty(searchTrigger)
           ChannelsICA = EEG.nbchan;
        else
           ChannelsICA = EEG.nbchan-1;
        end

        %Function to run ICA with specific parameters
        EEG = pop_runica(EEG, 'icatype', 'runica', 'extended',1,'interrupt','off','chanind',1:ChannelsICA);
        EEG = eeg_checkset( EEG );

        %Append "ICAWeights" to filename
        EEG = pop_editset(EEG, 'setname', newFileName);
        EEG = eeg_checkset( EEG );

        %Saving new file name to new path
        EEG = pop_saveset( EEG, 'filename',newFileName,'filepath',newFilePath);
        EEG = eeg_checkset( EEG );

        %Purge dataset from memory
        [ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
        EEG = pop_delset( EEG, [1] );
    end

end

%Display end message
if Filenum == numel(FilesList)
    displayedMessage = msgbox('Operation Completed');
end
