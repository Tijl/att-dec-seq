%% plot_decoding
addpath('~/CoSMoMVPA/mvpa')
addpath('~/fieldtrip');ft_defaults
addpath('~/Repository/CommonFunctions/Matplotlibcolors2/')
addpath('distributionPlot');

load('results_exp1/stats_decoding.mat','stats');
stats1 = stats;
load('results_exp2/stats_decoding.mat','stats');
stats2 = stats;
allstats = {stats1,stats2};


%%
f=figure(1);clf
f.Position=[f.Position(1:2) 700 500];f.PaperPositionMode='auto';f.Resize='off';

nboot = 10000;
                
linenr = 0;
h1=[];h2=[];
leglabs=[];
titles = {'Decoding: duration','Attention effect: duration','Decoding: peak time','Attention effect: peak time'};

for x=1:4
    subplot(2,2,x);
    title(sprintf('%s   %s','A'+x-1,titles{x}),'Position',[10 .2 .5],'FontSize',13);
end

timevect=stats1.timevect;

for x=1:4
    a=subplot(2,2,x);hold on
    a.XLim=[min(timevect),1000];
    a.YDir='reverse';
    xlabel('time (ms)')
    for i=1.5:4:8
        fill([timevect([1 end]),fliplr(timevect([1 end]))],[i-1 i-1 i+1 i+1],'k','FaceAlpha',.08,'EdgeAlpha',0)
    end
end

groupnames = {'object','concept'};
for group=1
    
    if group==1
        targetlabels = {'image','letter'};
    else
        targetlabels = {'animacy','category'};
    end
    
    
    co = vega10(10); %line colours
    co3 = vega20(20);co3=co3(2:2:end,:);
    
    co2 = [0 0 0]; %color for difference
    
    
    for t=1:2
        exporder = 1:2;
        if group==1 && t==2
            exporder = fliplr(exporder);
        end
        for exp = exporder
            stats = allstats{exp};
            expsize = {'large','small'};
            if group==1 && t==2
                expsize = fliplr(expsize);
            end            
            expsize = expsize{exp};
            
            %lines
            st = {'-',':'};
            if group==1 && t==2
                st = fliplr(st);
            end
            labs = {'attended','unattended','difference'};
            if group==1 && t==2
                conditionlabels = {'letter','object','difference'};
            else
                conditionlabels = {'object','letter','difference'};
            end
            linenr=linenr+1;
            for c=1:3
                
                s=stats.(conditionlabels{c}).(targetlabels{t});
                
                plot_shift = c==3;
                line_offset = (1-plot_shift)*(2*c-3)*.1+linenr;
                
                bootidx_peak = [];
                orig_peak = [];
                for bootnr=1:(nboot+1)
                    if bootnr>1
                        rng(bootnr);
                        x = s.x(randsample(1:s.n,s.n,1),:);
                    else
                        x = s.x;
                    end
                    [~,bootidx_peak(bootnr)] = max(abs(mean(x)));
                end
                %
                
                %duration
                subplot(2,2,1+plot_shift);            
                plot(timevect,line_offset+0*timevect,'k:')
                
                idx = s.fdr_adj_p<.05;
                plot(timevect(idx),line_offset+0*timevect(idx),'.','Color',co(c,:),'LineWidth',2);

                %peak
                subplot(2,2,3+plot_shift);
                
                idx_peak = bootidx_peak(1);
                dat = timevect(bootidx_peak(2:end))';
                bci = prctile(dat,[5,95]);
                
                plot(timevect,line_offset+0*timevect,'k:')
                opt = struct();
                switch c
                    case 1;opt.widthDiv=[2 1];opt.histOri='left';
                    case 2;opt.widthDiv=[2 2];opt.histOri='right';
                end
                opt.xyOri = 'flipped';
                opt.xValues = line_offset;
                opt.distWidth = .8;
                opt.color = co3(c,:);
                opt.showMM = 0;
                handles = distributionPlot(dat,opt);
                
                h2(c) = plot(timevect(idx_peak),line_offset+0*timevect(idx_peak),'-x','Color',co(c,:),'LineWidth',2,'MarkerSize',10);
                drawnow
            end
            leglabs{linenr} = sprintf('%s %s',expsize,strrep(targetlabels{t},'image','object'));
        end
    end
end

for x=1:4
    a=subplot(2,2,x);
    a.YLim=[0.5 4.5];
    a.YTick=1:4;
    a.YTickLabel=leglabs;
    
    idx = 1:2;
    if ismember(x,[2,4])
        idx = 3;
    end
    if x>2
        leg=legend(h2(idx),labs(idx),'Location','NE','orientation','vertical','Box','on');
        leg.FontSize=10;
        %leg.Position=[leg.Position(1) leg.Position(2) .12 .08];
    end
end

%% save
fn = 'figures/figure_summary';
tn = tempname;
print(gcf,'-dpng','-r500',tn)
im=imread([tn '.png']);
[i,j]=find(mean(im,3)<255);margin=2;
imwrite(im(min(i-margin):max(i+margin),min(j-margin):max(j+margin),:),[fn '.png'],'png');



