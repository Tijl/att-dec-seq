function stats_decoding()

    if isempty(which('cosmo_wtf'))
        addpath('~/CoSMoMVPA/mvpa')
    end
    
    r=.707;
    stats_cell={};
    
    parfor exp=1:2
    
        %% stack results
        suffix = 'decoding';
        fprintf('Loading data exp%i\n',exp)
        files = dir(sprintf('results_exp%i/sub-*_%s.mat',exp,suffix));
        res_cell={};
        cc = clock();mm='';
        for f=1:length(files)
            fn = sprintf('results_exp%i/%s',exp,files(f).name);
            x=load(fn,'res');
            res_avg={};
            for c=1:2
                for t=1:4
                    res_avg{c,t} = cosmo_average_samples(cosmo_slice(x.res,x.res.sa.condition==c & x.res.sa.targetnumber==t),'split_by',{});
                end
            end

            res_cell{f} = cosmo_stack(res_avg);
            mm = cosmo_show_progress(cc,f/length(files),sprintf('%i/%i',f,length(files)),mm);
        end
        res_all = cosmo_stack(res_cell);

        %% BFs
        fprintf('Computing stats exp%i\n',exp)
        tloop = unique(res_all.sa.targetlabel);
        cloop = unique(res_all.sa.conditionlabel);
        stats = struct();
        timevect = res_all.a.fdim.values{1};
        cc = clock();mm='';
        for t=1:length(tloop)
            for c=0:length(cloop)
                if c>0
                    %against chance
                    idx = strcmp(res_all.sa.conditionlabel,cloop{c}) & strcmp(res_all.sa.targetlabel,tloop{t});
                    x = res_all.samples(idx,:);
                    tlower=.5;
                    tail = 'right';
                else
                    % difference
                    idx1 = strcmp(res_all.sa.conditionlabel,cloop{1}) & strcmp(res_all.sa.targetlabel,tloop{t});
                    idx2 = strcmp(res_all.sa.conditionlabel,cloop{2}) & strcmp(res_all.sa.targetlabel,tloop{t});
                    x = res_all.samples(idx1,:)-res_all.samples(idx2,:);
                    tlower=0;
                    tail = 'both';
                end
                    
                s = struct();
                s.n = size(x,1);
                s.mu = mean(x);
                s.se = std(x)./sqrt(s.n);
                s.x = x;
                s.tlower = tlower;
                s.tail = tail;
                s.tstat = (s.mu-s.tlower)./s.se;
                s.bf = t1smpbf(s.tstat,s.n,r);

                s.p_uncor = arrayfun(@(y) signrank(x(:,y),s.tlower,'tail',s.tail),1:size(x,2));
                [~,~,s.fdr_adj_p]=fdr(s.p_uncor);

                if c>0
                    stats.(cloop{c}).(tloop{t}) = s;
                else
                    stats.difference.(tloop{t}) = s;
                end
            end
            mm = cosmo_show_progress(cc,t/length(tloop),sprintf('%i/%i %s',t,length(tloop),tloop{t}),mm);
        end
        stats.format = 'stats.condition.target.x';
        stats.timevect = res_all.a.fdim.values{1};
        stats_cell{exp} = stats;
    end
    
    %%
    for exp=1:2
        fprintf('Saving exp%i\n',exp)
        stats = stats_cell{exp};
        save(sprintf('results_exp%i/stats_decoding.mat',exp),'stats');
        fprintf('Done\n')
    end
    