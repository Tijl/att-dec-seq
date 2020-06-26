function run_decoding(subjectnr,exp)
    
    if ismac
        if isempty(which('cosmo_wtf'))
            addpath('~/CoSMoMVPA/mvpa')
        end
        nproc = 2;
    else %on HPC
        addpath('../CoSMoMVPA/mvpa');
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
    
    %%
    fn = sprintf('data_exp%i/derivatives/cosmomvpa/sub-%02i_task-rsvp_cosmomvpa.mat',exp,subjectnr);
    outfn = sprintf('results_exp%i/sub-%02i_decoding.mat',exp,subjectnr);
    fprintf('loading %s\n',fn);tic
    load(fn,'ds')
    fprintf('loading data finished in %i seconds\n',ceil(toc))
    
    %%
    ma={};
    ma.classifier = @cosmo_classify_lda;
    ma.nproc = nproc;
    ma.check_partitions = false;
    ma.output='fold_accuracy';
    nh = cosmo_interval_neighborhood(ds,'time','radius',0);
    conditions = [0 1];
    conditionlabels = {'object','letter'};
    res = cell(2,4);
    
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
            cvtargets = {dsb.sa.objectstimnumber,dsb.sa.objectstimnumber,dsb.sa.objectstimnumber,dsb.sa.letterstimnumber};
                        
            dsb.sa.targets = targets{t};
            dsb.sa.cvtargets = cvtargets{t};
            %image by sequence
            % all pairwise combinations
            combs = combnk(unique(dsb.sa.targets,'rows'),2);
            uc = unique(dsb.sa.chunks);
            ma.partitions = struct();
            ma.partitions.train_indices = {};
            ma.partitions.test_indices = {};
            sa=struct('target1',[],'target2',[],'leftoutchunk',[],'leftoutexemplar1',[],'leftoutexemplar2',[],'condition',[],'targetnumber',[],'conditionlabel',[],'targetlabel',[]);
            for i=1:size(combs,1) %pairwise comparision to test
                % find the epochs of this pair
                idx1 = ismember(dsb.sa.targets,combs(i,:));
                % ue1 and ue2 are the unique exemplars (to leave out in the test set)
                ue1 = unique(dsb.sa.cvtargets(dsb.sa.targets==combs(i,1)));
                ue2 = unique(dsb.sa.cvtargets(dsb.sa.targets==combs(i,2)));
                % leave all combinations of exemplar pairs out once for exempar-by-sequence-crossval
                ue = [repelem(ue1,length(ue2),1) repmat(ue2,length(ue1),1)];
                for j=1:length(uc) % chunk to leave out
                    idx2 = dsb.sa.chunks==uc(j);
                    for k=1:size(ue,1) % for each exemplar pair to leave out
                        % store targets in results
                        sa.target1(end+1,1) = combs(i,1);
                        sa.target2(end+1,1) = combs(i,2);
                        % store left out chunk and exemplar in result
                        sa.leftoutchunk(end+1,1) = uc(j);
                        sa.leftoutexemplar1(end+1,1) = ue(k,1);
                        sa.leftoutexemplar2(end+1,1) = ue(k,2);
                        % store condition and target in result
                        sa.targetlabel{end+1,1} = targetlabels{t};
                        sa.conditionlabel{end+1,1} = conditionlabels{c};
                        sa.targetnumber(end+1,1) = t;
                        sa.condition(end+1,1) = c;
                        % set partitions
                        % if size(ue,1)>1 then we are doing
                        % exemplar-by-sequence (otherwise just sequence,
                        % for the lowest (image) level)
                        if size(ue,1)>1
                            idx3 = ismember(dsb.sa.cvtargets,ue(k,:));
                            ma.partitions.train_indices{1,end+1} = find(idx1 & ~idx2 & ~idx3);
                            ma.partitions.test_indices{1,end+1} = find(idx1 & idx2 & idx3);
                        else
                            ma.partitions.train_indices{1,end+1} = find(idx1 & ~idx2);
                            ma.partitions.test_indices{1,end+1} = find(idx1 & idx2);
                        end
                    end
                end
            end
            r = cosmo_searchlight(dsb,nh,@cosmo_crossvalidation_measure,ma);
            % merge fold information into result (targets, left out chunk & exemplar)
            r.sa = cosmo_structjoin(r.sa,sa);
            
            res{c,t} = r;
        end
    end
    res = cosmo_stack(res);
    
    save(outfn,'res','-v7.3')
    
