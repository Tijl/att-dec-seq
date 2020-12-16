%% behavioural
addpath('~/CoSMoMVPA/mvpa/')
addpath('~/Repository/CommonFunctions/Matplotlibcolors2/')

%% get pp info
T = {readtable('data_exp1/participants.tsv','FileType','text'),...
    readtable('data_exp2/participants.tsv','FileType','text')};
for e=1:2
    fprintf('exp %i:\n %i female, %i male; mean age %.2f years; age range %i-%i years\n',...
        e,sum(strcmpi(T{e}.gender,'F')),sum(strcmpi(T{e}.gender,'M')),...
        mean(T{e}.age),min(T{e}.age),max(T{e}.age))
end

%%
f=figure(1);clf
f.Position=[f.Position([1 2]) 800 400];f.PaperPositionMode='auto';f.Resize='off';
for exp = 1:2
    datafn = sprintf('data_exp%i',exp);
    nsubjects = length(dir([datafn '/sub*']));
    c=clock();mm='';
    hitrate_object=[];hitrate_letter=[];
    for subjectnr = 1:nsubjects
        T = readtable(sprintf('%s/sub-%02i/eeg/sub-%02i_task-rsvp_events.csv',datafn,subjectnr,subjectnr));
        
        %for a rough estimate of RT, we need to find the last 2back events
        idx_correct = find(T.correct);
        i2 = find(T.is2back);
        [~,idx] = min(abs(idx_correct'-i2));
        idx_2back = i2(idx);
        T.rel_rt = T.rt;
        T.rel_rt(idx_correct) = T.rt(idx_correct)-T.time_stimon(idx_2back);
        %note RT is not very accurate due to experiment code
        rt_object(subjectnr) = mean(T.rel_rt(T.correct & T.condition==0));
        rt_letter(subjectnr) = mean(T.rel_rt(T.correct & T.condition==1));

        hitrate_object(subjectnr) = (sum(T.correct & T.condition==0)/sum(T.is2back & T.condition==0));
        hitrate_letter(subjectnr) = (sum(T.correct & T.condition==1)/sum(T.is2back & T.condition==1));
        
        farate_object(subjectnr) = (sum(T.rt>0 & ~T.correct & T.condition==0)/sum(T.rt>0 & T.condition==0));
        farate_letter(subjectnr) = (sum(T.rt>0 & ~T.correct & T.condition==1)/sum(T.rt>0 & T.condition==1));
        
        mm=cosmo_show_progress(c,subjectnr/nsubjects,'',mm);
    end

    %%
%     dprime_objects = norminv(hitrate_object)-norminv(max(farate_object,0.01));
%     dprime_letters = norminv(hitrate_letter)-norminv(max(farate_letter,0.01));
%     hitrate_object = dprime_objects;
%     hitrate_letter = dprime_letters;    
    
    mu_r = mean([rt_object; rt_letter],2);
    se_r = std([rt_object; rt_letter],[],2)./sqrt(nsubjects);
    
    fprintf('\nexp%i: mean RT = %.4fs (objects) %.4fs (letters) (se = %.4fs / %.4fs)\n',exp,mu_r,se_r);
    
    mu_h = mean([hitrate_object; hitrate_letter],2);
    se_h = std([hitrate_object; hitrate_letter],[],2)./sqrt(nsubjects);
    
    fprintf('\nexp%i: mean hitrate = %.2f%% (objects) %.2f%% (letters) (se = %.4f%% / %.4f%%)\n',exp,100*mu_h,100*se_h);

    fprintf('\nexp%i: mean hitrate = %.2f%% (se = %.4f%%)\n',exp,100*mean(mu_h),100*mean(se_h));

    
    %% 
    mudiff = mean(hitrate_object-hitrate_letter);
    sediff = std(hitrate_object-hitrate_letter)./sqrt(nsubjects);
    t = mudiff/sediff;
    BF10h = t1smpbf(t,nsubjects);

    shift = linspace(-.1,.1,nsubjects);rng(1);shift = randsample(shift,nsubjects);
    co=inferno(nsubjects+5);
    for subjectnr = 1:nsubjects
        x=shift(subjectnr)+[1 2];
        y1=[hitrate_object(subjectnr) hitrate_letter(subjectnr)];
        a1 = subplot(1,2,exp);hold on
        for i=1:2
            fill(i+.2*[-1 1 1 -1],mu_h(i)*[0 0 1 1],'k','FaceAlpha',0)
            line(i+[0 0],mu_h(i)+se_h(i)*[-1 1],'Color','k')
            line(i+.1*[-1 1],mu_h(i)-se_h(i)*[1 1],'Color','k')
            line(i+.1*[-1 1],mu_h(i)+se_h(i)*[1 1],'Color','k')
        end
        h1=plot(x,y1);
        a1.XLim=[0.5 2.5];  
        h1.Marker='o';
        h1.Color=.85*[1 1 1];
        h1.MarkerFaceColor='w';
        h1.MarkerEdgeColor=co(subjectnr,:);
        a1.YLim=[0 1];
    end
    a1.YTick = linspace(0,1.5,6);
    a1.YLabel.String='Proportion of HITs';
    if exp==1
        title(a1,'A      Experiment 1','Units','Normalized','Position',[-.15 1.02 0],'HorizontalAlignment','left','FontSize',16)
    else
        title(a1,'B      Experiment 2','Units','Normalized','Position',[-.15 1.02 0],'HorizontalAlignment','left','FontSize',16)
    end
    a1.XTick=[1 2];
    a1.XTickLabel={'Report object','Report letter'};
    text(a1,1.5,a1.YLim(1)+.06*diff(a1.YLim),sprintf('BF_{10} = %.3f',BF10h),'HorizontalAlignment','center','Color','k')

    % image
    ss = 63;
    fn = sprintf('screenshots_exp%i/screen_%05i.png',exp,ss);
    im = imread(fn);
    im = im(275:425,275:425,:);
    image('XData',[.55 .95],'YData',max(a1.YLim)-diff(a1.YLim)*[.18 .01],'CData',flipud(im));
    drawnow
end

%%
fn = 'figures/figure_behaviour_combined';
tn = tempname;
print(gcf,'-dpng','-r500',tn)
im=imread([tn '.png']);
[i,j]=find(mean(im,3)<255);margin=2;
imwrite(im(min(i-margin):max(i+margin),min(j-margin):max(j+margin),:),[fn '.png'],'png');
