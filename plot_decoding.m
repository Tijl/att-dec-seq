%% plot_decoding
addpath('~/CoSMoMVPA/mvpa')
addpath('~/fieldtrip');ft_defaults
addpath('~/Repository/CommonFunctions/Matplotlibcolors2/')

load('results_exp1/stats_decoding.mat','stats');
stats1 = stats;
load('results_exp2/stats_decoding.mat','stats');
stats2 = stats;
allstats = {stats1,stats2};

%%
res_cell_exp1={};res_cell_exp2={};cc=clock();mm='';
for s=1:20
    fn = sprintf('results_exp1/sub-%02i_ch_searchlight_multiclass.mat',s);
    try
        load(fn,'res')
        res_cell_exp1{end+1} = res;
    catch
    end
    fn = sprintf('results_exp2/sub-%02i_ch_searchlight_multiclass.mat',s);
    try
        load(fn,'res')
        res_cell_exp2{end+1} = res;
    catch
    end
    mm=cosmo_show_progress(cc,s/20,[],mm);
end
res_ch_searchlight_exp1 = cosmo_stack(res_cell_exp1);
res_ch_searchlight_exp2 = cosmo_stack(res_cell_exp2);

%%
groupnames = {'object','concept'};
for group=1:2

    %%
    f=figure(1);clf
    f.Position=[f.Position(1:2) 1000 1200];f.PaperPositionMode='auto';f.Resize='off';

    if group==1
        targetlabels = {'image','letter'};
    else
        targetlabels = {'animacy','category'};
    end
    conditionlabels = {'object','letter'};

    timevect=stats.timevect;
    
    co = vega10(10); %line colours
    
    co2 = [0 0 0]; %color for difference
    
    ms=5;
    zc=.5*[1 1 1];
    
    for exp = 1:2
        stats = allstats{exp};
                
        aw = .4;
        for t=1:2
            a=axes('Position',[.07+(.1+aw)*(exp-1) .27+(1-.5*t) aw .18]);
            hold on
            plot(timevect,.5+0*timevect,'k--')

            labs = {'attended','unattended'};
            if group==1 && t==2
                labs = fliplr(labs);
            end
            leglabs = {sprintf('report object (%s)',labs{1}),...
                       sprintf('report letter (%s)',labs{2})};

            a.XLim=[min(timevect) max(timevect)];
            if group==2
                a.YLim=[.485 .56];
            else
                if t==2
                    a.YLim=[.49 .535];
                else
                    a.YLim=[.485 .62];
                end
            end
            %se
            for c=1:2
                s=stats.(conditionlabels{c}).(targetlabels{t});
                fill([timevect,fliplr(timevect)],[s.mu-s.se fliplr(s.mu+s.se)],co(c,:),'FaceAlpha',.2,'EdgeAlpha',0)
            end
            %lines
            h=[];st = {'-',':'};
            if group==1 && t==2
                st = fliplr(st);
            end
            for c=1:2
                s=stats.(conditionlabels{c}).(targetlabels{t});
                h(c) = plot(timevect,s.mu,'Color',co(c,:),'LineWidth',2,'LineStyle',st{c});
            end
            a.TickDir='out';a.TickLength=[.005 0];
            leg=legend(h,leglabs,'Location','NE');
            leg.Box='off';leg.Orientation='Vertical';
            ylabel('Decoding accuracy')
            a.FontSize=14;leg.FontSize=14;
            title(sprintf('%s    Experiment %i - Decoding %s',char('A'+2*(t-1)+exp-1),exp,strrep(targetlabels{t},'image','object')),'Units','Normalized','Position',[-.065,1.05,1],'FontSize',16,'HorizontalAlignment','left')

            % image
            ss = 63;
            fn = sprintf('screenshots_exp%i/screen_%05i.png',exp,ss);
            im = imread(fn);
            im = im(275:425,275:425,:);
            image('XData',-10+80*[-1 1],'YData',max(a.YLim)-diff(a.YLim)*[.28 .01],'CData',flipud(im));
            drawnow

            %ch searchlights
            for c=1:2
                if exp==1
                    r1 = cosmo_slice(res_ch_searchlight_exp1,...
                        strcmp(res_ch_searchlight_exp1.sa.targetlabel,targetlabels{t}) & ...
                        strcmp(res_ch_searchlight_exp1.sa.conditionlabel,conditionlabels{c}));
                else
                    r1 = cosmo_slice(res_ch_searchlight_exp2,...
                        strcmp(res_ch_searchlight_exp2.sa.targetlabel,targetlabels{t}) & ...
                        strcmp(res_ch_searchlight_exp2.sa.conditionlabel,conditionlabels{c}));
                end
                res = cosmo_average_samples(r1,'split_by',{});
                if strcmp(targetlabels{t},'animacy')
                    h0mean = 1/2;
                elseif strcmp(targetlabels{t},'category')
                    h0mean = 1/4;
                else
                    h0mean = 1/16;
                end
                res.samples = res.samples - h0mean;
                
                ft = ft_timelockanalysis([],cosmo_map2meeg(res));
                mrange = [0 1]*prctile(res.samples(:)',99);
                
                timewins = [(-100:100:950)' (0:100:1000)'];
                layout=cosmo_meeg_find_layout(res);
                for ttt=1:length(timewins)
                    bfh = .04;
                    aw2 = .4./length(timewins);
                    if t==2 && group==1
                        a=axes('Position',[.07+(.1+aw)*(exp-1)+ttt*aw2-aw2 .13+(1-.5*t)+bfh*(c) aw2 .8*bfh]);hold on
                    else
                        a=axes('Position',[.07+(.1+aw)*(exp-1)+ttt*aw2-aw2 .13+(1-.5*t)+bfh*(3-c) aw2 .8*bfh]);hold on
                    end
                    co3 = [linspace(1,co(c,1),5);...
                           linspace(1,co(c,2),5);...
                           linspace(1,co(c,3),5)]';
                    % show figure with plots for each sensor
                    cfg = [];
                    cfg.zlim = mrange;
                    cfg.xlim = timewins(ttt,:);
                    cfg.layout = layout;
                    cfg.showscale = 'no';
                    cfg.comment = 'no';
                    cfg.markersymbol = '.';
                    cfg.style = 'straight';
                    cfg.gridscale = 128;
                    ft_topoplotER(cfg, ft);
                    a.FontSize = 12;
                    a.Colormap = co3;
                    set(a.Children,'LineWidth',.5)
                end
                drawnow;
            end
            
            % BF
            co(3,:) = co2(1,:);
            for c=1:3
                bfh = .04;
                if c<3 && t==2 && group==1
                    a=axes('Position',[.07+(.1+aw)*(exp-1) .05+(1-.5*t)+bfh*(c) aw .8*bfh]);hold on
                else
                    a=axes('Position',[.07+(.1+aw)*(exp-1) .05+(1-.5*t)+bfh*(3-c) aw .8*bfh]);hold on                    
                end
                    
                a.FontSize=14;
                if c<3
                    bf = stats.(conditionlabels{c}).(targetlabels{t}).bf;
                    pvals = stats.(conditionlabels{c}).(targetlabels{t}).fdr_adj_p;
                else
                    bf = stats.difference.(targetlabels{t}).bf;
                    pvals = stats.difference.(targetlabels{t}).fdr_adj_p;
                end
                x = zeros(size(bf));
                for z=-1:2
                    hp=plot([min(timevect) max(timevect)],z*[1 1],'-','Color',zc,'LineWidth',1);
                    if z
                        hp.LineStyle = ':';
                    end
                end
                idx = bf<1/3;
                plot(timevect(idx),-.5+x(idx),'o','Color',co(c,:),'MarkerSize',ms,'MarkerFaceColor',co(c,:));
                idx = bf>10;
                plot(timevect(idx),.5+x(idx),'o','Color',co(c,:),'MarkerSize',ms,'MarkerFaceColor',co(c,:));
                idx = pvals<.05;
                plot(timevect(idx),1.5+x(idx),'o','Color',co(c,:),'MarkerSize',ms,'MarkerFaceColor',co(c,:));

                if c<3
                    tt = strrep(labs{c},'task-','');
                    a.XTickLabel=[];
                else
                    tt='difference';
                end
                if exp==1
                    tt=text(1130,.5,tt,'HorizontalAlignment','center','VerticalAlignment','middle','FontSize',a.FontSize,'Color',co(c,:));
                end
                a.XLim=[min(timevect) max(timevect)];
                a.YLim=[-1 2];a.YTick=-.5:1.5;
                if exp==1
                    a.YTickLabel={'BF < 1/3','BF > 10','p < 0.05'};
                else
                    a.YTickLabel= [];
                end                
                a.YAxis.FontSize=12;
                a.TickDir='out';a.TickLength=[.005 0];
            end
            xlabel('time (ms)')
        end
    end

    %%
    fn = sprintf('figures/figure_decoding_%s',groupnames{group});
    tn = tempname;
    print(gcf,'-dpng','-r500',tn)
    im=imread([tn '.png']);
    [i,j]=find(mean(im,3)<255);margin=2;
    imwrite(im(min(i-margin):max(i+margin),min(j-margin):max(j+margin),:),[fn '.png'],'png');
end