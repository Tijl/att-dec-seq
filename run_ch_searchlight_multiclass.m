function run_ch_searchlight_multiclass(subjectnr,exp)
    
    if ismac
        addpath('~/CoSMoMVPA/mvpa')
        addpath('~/fieldtrip')
        nproc = 1;
    else
        addpath('../CoSMoMVPA/mvpa');
        addpath('../fieldtrip')
        % start cluster, give it a unique directory
        % starting a pool can fail when 2 procs are requesting simultaneous
        % thus try again after a second until success
        pool=[];
        while isempty(pool) 
            try
                pc = parcluster('local');
                pc.JobStorageLocation=tempdir;
                pool=parpool(pc);
            catch err
                disp(err)
                delete(gcp('nocreate'));
                pause(1)
            end
        end
        nproc=cosmo_parallel_get_nproc_available();
    end
    ft_defaults;
    
    cosmo_warning('off')
    
    %%
    fn = sprintf('data_exp%i/derivatives/cosmomvpa/sub-%02i_task-rsvp_cosmomvpa.mat',exp,subjectnr);
    outfn = sprintf('results_exp%i/sub-%02i_ch_searchlight_multiclass.mat',exp,subjectnr);
    fprintf('loading %s\n',fn);tic
    load(fn,'ds')
    fprintf('loading data finished in %i seconds\n',ceil(toc))
    
    %%
    ma={};
    ma.classifier = @cosmo_classify_lda;
    ma.nproc = nproc;
    nh1 = cosmo_meeg_chan_neighborhood(ds,'count',4,'label','layout','label_threshold',.99);
    nh2 = cosmo_interval_neighborhood(ds,'time','radius',0);
    nh = cosmo_cross_neighborhood(ds,{nh1,nh2});
    conditions = [0 1];
    conditionlabels = {'object','letter'};
    res_cell = cell(2,4);
    
    for c=1:length(conditions)
        targetlabels = {'animacy','category','image','letter'};
        for t=1:4
            fprintf('subject %i condition:%s decoding:%s\n',subjectnr,conditionlabels{c},targetlabels{t})
            if t<4
                dsb = cosmo_slice(ds,ds.sa.condition==conditions(c) & ~ds.sa.objecttarget);
            else
                dsb = cosmo_slice(ds,ds.sa.condition==conditions(c) & ~ds.sa.lettertarget);
            end
            dsb.sa.chunks = dsb.sa.streamnumber;
            targets = {double(dsb.sa.objectstimnumber>7),floor(dsb.sa.objectstimnumber/4),dsb.sa.objectstimnumber,dsb.sa.letterstimnumber};
            dsb.sa.targets = targets{t};
            %image by sequence all to all
            ma.partitions = cosmo_nfold_partitioner(dsb);
            r = cosmo_searchlight(dsb,nh,@cosmo_crossvalidation_measure,ma);
            r.sa.subjectnr = subjectnr;
            r.sa.targetnumber = t;
            r.sa.conditionnumber = c;
            r.sa.targetlabel = targetlabels(t);
            r.sa.conditionlabel = conditionlabels(c);
            res_cell{c,t} = r;
        end
    end
    
    %% save
    res = cosmo_stack(res_cell);
    save(outfn,'res','-v7.3')
    