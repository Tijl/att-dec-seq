%% plot decoding differences
addpath('~/CoSMoMVPA/mvpa')
addpath('~/fieldtrip');ft_defaults
addpath('~/Repository/CommonFunctions/Matplotlibcolors2/')

x=load('results_exp1/stats_decoding.mat','stats');
stats_exp1=x.stats;
x=load('results_exp2/stats_decoding.mat','stats');
stats_exp2=x.stats;

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

f=figure(1);clf
f.Position=[f.Position(1:2) 1000 1000];f.PaperPositionMode='auto';f.Resize='off';

timevect=stats_exp1.timevect;
targetlabels = {'image','letter'};
conditionlabels = {'object','letter'};

for t=1:2
    co = vega10(10); %line colours
    co = co([4 10],:);
    ms=5;
    zc=.5*[1 1 1];
    if t==2;co = flipud(co);end
    a=axes('Position',[.1 .26+(1-.5*t) .8 .21]);
    a.FontSize=12;
    hold on
    plot(timevect,0*timevect,'k--')

    labs = {'task-relevant','task-irrelevant'};
    if t==2
        labs = fliplr(labs);
    end
    leglabs = {sprintf('report object (%s)',labs{1}),...
               sprintf('report letter (%s)',labs{2})};

    a.XLim=[min(timevect) max(timevect)];

    %fill
    s=stats_exp1.difference.(targetlabels{t});
    fill([timevect,fliplr(timevect)],(t*2-3).*[s.mu-s.se fliplr(s.mu+s.se)],co(1,:),'FaceAlpha',.2,'EdgeAlpha',0)
    
    s=stats_exp2.difference.(targetlabels{t});
    fill([timevect,fliplr(timevect)],(t*2-3).*[s.mu-s.se fliplr(s.mu+s.se)],co(2,:),'FaceAlpha',.2,'EdgeAlpha',0)
        
    %lines
    h=[];
    s=stats_exp1.difference.(targetlabels{t});
    h(1) = plot(timevect,(t*2-3).*s.mu,'-','Color',co(1,:),'LineWidth',2);
    s=stats_exp2.difference.(targetlabels{t});
    h(2) = plot(timevect,(t*2-3).*s.mu,'-','Color',co(2,:),'LineWidth',2);
    if t==1
        leg = legend(fliplr(h),{'Small objects (Experiment 2)','Big objects (Experiment 1)'});
    else
        leg = legend(h,{'Small letters (Experiment 1)','Big letters (Experiment 2)'});
    end
    leg.Box = 'off';
    leg.FontSize = 12;
    leg.Orientation = 'horizontal';
    a.YLim=[-.019 .049];
    xlabel('time (ms)')
    ylabel({[strrep(targetlabels{t},'image','object') ' decoding accuracy'],'relevant - irrelevant'})
    tx = title(sprintf('%s     Effect of task on %s decoding',char('A'+t-1),conditionlabels{t}),...
        'HorizontalAlignment','Left','Position',[-200 max(a.YLim) 0],'FontSize',16);
    
    
    % images
    for c = 1:2
        ss = 63;
        fn = sprintf('screenshots_exp%i/screen_%05i.png',1+(t==c),ss);
        im = imread(fn);
        im = im(275:425,275:425,:);
        for x = 1:3
            for y = 1:10
                im(y,:,x) = 255*co(1+(t==c),x);
                im(:,y,x) = 255*co(1+(t==c),x);
                im(:,end-y,x) = 255*co(1+(t==c),x);
                im(end-y,:,x) = 255*co(1+(t==c),x);
            end
        end        
        image('XData',430+40*[-1 1]+c*250,'YData',max(a.YLim)-.01-diff(a.YLim)*[.25 .01],'CData',flipud(im));
    end
    drawnow
    
    %ch searchlights
    for c=1:2
        if c==1
            r1 = cosmo_slice(res_ch_searchlight_exp1,...
                strcmp(res_ch_searchlight_exp1.sa.targetlabel,targetlabels{t}) & ...
                strcmp(res_ch_searchlight_exp1.sa.conditionlabel,'object'));
            r2 = cosmo_slice(res_ch_searchlight_exp1,...
                strcmp(res_ch_searchlight_exp1.sa.targetlabel,targetlabels{t}) & ...
                strcmp(res_ch_searchlight_exp1.sa.conditionlabel,'letter'));
        else
            r1 = cosmo_slice(res_ch_searchlight_exp2,...
                strcmp(res_ch_searchlight_exp2.sa.targetlabel,targetlabels{t}) & ...
                strcmp(res_ch_searchlight_exp2.sa.conditionlabel,'object'));
            r2 = cosmo_slice(res_ch_searchlight_exp2,...
                strcmp(res_ch_searchlight_exp2.sa.targetlabel,targetlabels{t}) & ...
                strcmp(res_ch_searchlight_exp2.sa.conditionlabel,'letter'));
        end
        if t==1
            r1.samples = r1.samples - r2.samples;
        else
            r1.samples = r2.samples - r1.samples;
        end
        res = cosmo_average_samples(r1,'split_by',{});
        ft = ft_timelockanalysis([],cosmo_map2meeg(res));
        mrange = [0 1]*prctile(res.samples(:)',99);
                
        timewins = [(-100:50:950)' (-50:50:1000)'];
        layout=cosmo_meeg_find_layout(res);
        for ttt=1:length(timewins)
            bfh = .042;
            aw = .8./length(timewins);
            if t==1
                a=axes('Position',[.1+ttt*aw-aw .09+(1-.5*t)+bfh*(c) aw .8*bfh]);hold on
            else
                a=axes('Position',[.1+ttt*aw-aw .09+(1-.5*t)+bfh*(3-c) aw .8*bfh]);hold on
            end
            co2 = [linspace(1,co(c,1),5);...
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
            a.Colormap = co2;
            set(a.Children,'LineWidth',.5)
        end
        ttt = {'Small','Big'};
        if t==1
            ttt = fliplr(ttt);
        end
        tt=sprintf('%s %ss',ttt{c},conditionlabels{t});
        tt=text(max(a.XLim)*1.4,mean(a.YLim),tt,'VerticalAlignment','middle','FontSize',12,'Color',co(c,:));

        drawnow;
    end
    
    %% bfs
    for c=1:2
        bfh = .042;
        if t==1
            a=axes('Position',[.1 (1-.5*t)+bfh*(c) .8 .8*bfh]);hold on
        else
            a=axes('Position',[.1 (1-.5*t)+bfh*(3-c) .8 .8*bfh]);hold on
        end
        switch c
            case 1
                bf = stats_exp1.difference.(targetlabels{t}).bf;
                pvals = stats_exp1.difference.(targetlabels{t}).fdr_adj_p;
            case 2
                bf = stats_exp2.difference.(targetlabels{t}).bf;
                pvals = stats_exp2.difference.(targetlabels{t}).fdr_adj_p;
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
        ttt = {'Small','Big'};
        if t==1
            ttt = fliplr(ttt);
        end
        tt=sprintf('%s %ss',ttt{c},conditionlabels{t});
        tt=text(max(timevect)*1.01,.5,tt,'VerticalAlignment','middle','FontSize',12,'Color',co(c,:));
        a.XLim=[min(timevect) max(timevect)];
        a.YLim=[-1 2];a.YTick=-.5:1.5;a.YTickLabel={'BF < 1/3','BF > 10','p < 0.05'};
        a.YAxis.FontSize=8;
        a.TickDir='out';a.TickLength=[.005 0];
        if c==3
            xlabel('time (ms)')
        else
            a.XTickLabel=[];
        end
        a.FontSize=12;
    end
end

%% save
fn = 'figures/figure_attention_effect';
tn = tempname;
print(gcf,'-dpng','-r500',tn)
im=imread([tn '.png']);
[i,j]=find(mean(im,3)<255);margin=2;
imwrite(im(min(i-margin):max(i+margin),min(j-margin):max(j+margin),:),[fn '.png'],'png');