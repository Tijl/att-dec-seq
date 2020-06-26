function preprocessing_fastdouble(partid,exp)

    %% eeglab
    if ~ismac
        addpath('../CoSMoMVPA/mvpa')
        addpath('../eeglab')
    end
    eeglab

    %% get files

    datapath = sprintf('data_exp%i',exp);
    
    contfn = sprintf('%s/derivatives/eeglab/sub-%02i_task-rsvp_continuous.set',datapath,partid);
    if isfile(contfn)
        fprintf('Using %s\n',contfn)
    	EEG_cont = pop_loadset(contfn);
    else
        % load EEG file
        EEG_raw = pop_loadbv(sprintf('%s/sub-%02i/eeg/',datapath,partid), sprintf('sub-%02i_task-rsvp_eeg.vhdr',partid));
        EEG_raw = eeg_checkset(EEG_raw);
        EEG_raw.setname = partid;
        EEG_raw = eeg_checkset(EEG_raw);

        % re-reference
        EEG_raw = pop_chanedit(EEG_raw, 'append',1,'changefield',{2 'labels' 'Cz'},'setref',{'' 'Cz'});
        EEG_raw = pop_reref(EEG_raw, [],'refloc',struct('labels',{'Cz'},'type',{''},'theta',{0},'radius',{0},'X',{5.2047e-15},'Y',{0},'Z',{85},'sph_theta',{0},'sph_phi',{90},'sph_radius',{85},'urchan',{1},'ref',{''},'datachan',{0}));

        % high pass filter
        EEG_raw = pop_eegfiltnew(EEG_raw, 0.1,[]);

        % low pass filter
        EEG_raw = pop_eegfiltnew(EEG_raw, [],100);

        % downsample
        EEG_raw = pop_resample( EEG_raw, 250);
        EEG_raw = eeg_checkset(EEG_raw);
        
        % create eventlist
        EEG_cont = pop_creabasiceventlist( EEG_raw , 'AlphanumericCleaning', 'on', 'BoundaryNumeric', { -99 }, 'BoundaryString', { 'boundary' });
        EEG_cont = eeg_checkset(EEG_cont);
        
        pop_saveset(EEG_cont,contfn);
    end
    
    %% add eventinfo to events
    eventsfncsv = sprintf('%s/sub-%02i/eeg/sub-%02i_task-rsvp_events.csv',datapath,partid,partid);
    eventsfntsv = sprintf('%s/sub-%02i/eeg/sub-%02i_task-rsvp_events.tsv',datapath,partid,partid);
    eventlist = readtable(eventsfncsv);
    
    idx = strcmp({EEG_cont.event.codelabel},'E1');
    if sum(idx)>height(eventlist)
        e = sum(idx)-height(eventlist);
        fprintf('Too many triggers. Found %i triggers, should be %i... deleting first %i triggers.\n',sum(idx),height(eventlist),e);
        idx(find(idx,e)) = 0;
    end    
    onset = vertcat(EEG_cont.event(idx).latency);
    duration = 100*ones(size(onset));

    neweventlist = [table(onset,duration,'VariableNames',{'onset','duration'}) eventlist];

    writetable(neweventlist,eventsfntsv,'filetype','text','Delimiter','\t')
    
    %% run binlister for bins and extract bin-based epochs
    EEG_cont = pop_binlister( EEG_cont , 'BDF', sprintf('makebins.txt'), 'IndexEL',  1, 'SendEL2', 'EEG', 'Voutput', 'EEG', 'ExportEL', tempname);
    EEG_cont = pop_epochbin( EEG_cont , [-100  1000], 'none'); % no baseline correct
    EEG_cont = eeg_checkset(EEG_cont);
    if size(EEG_cont.data,3)>height(eventlist)
        e = size(EEG_cont.data,3)-height(eventlist);
        fprintf('Too many epochs. Found %i epochs, should be %i... deleting first %i epochs.\n',size(EEG_cont.data,3),height(eventlist),e);
        EEG_cont.data(:,:,1:e) = [];
    end
    
    %% convert to cosmo
    ds = cosmo_flatten(permute(EEG_cont.data,[3 1 2]),{'chan','time'},{{EEG_cont.chanlocs.labels},EEG_cont.times},2);
    ds.a.meeg=struct(); %or cosmo thinks it's not a meeg ds 
    ds.sa = table2struct(eventlist,'ToScalar',true);
    cosmo_check_dataset(ds,'meeg');
    
    %% save epochs
    fprintf('Saving.\n');
    save(sprintf('%s/derivatives/cosmomvpa/sub-%02i_task-rsvp_cosmomvpa.mat',datapath,partid),'ds')
    fprintf('Finished.\n');
end
