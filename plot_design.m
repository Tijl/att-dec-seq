%% plot design

f=figure(1);clf;
f.Position=[f.Position(1:2) 700 800];f.Resize='off';

% top row: stimuli
fns = flipud(dir('stimuli/*.png'));
im={};alpha={};
for i = 1:16
    [im{i},~,alpha{i}] = imread(['stimuli' filesep fns(i).name]);
end

aw1=100;
bottom = 300;
for i=1:16
    a=axes('Units','Pixels','Position',[50+mod(i-1,4)*aw1 bottom+ceil(i/4)*aw1 aw1 aw1],'Box','on');
    image(im{i},'AlphaData',alpha{i});
    axis([-10 235 -10 235])
    a.XTick=[];a.YTick=[];
    axis off
    if ~mod(i,4)
        n = strsplit(fns(i).name,'_');
        %text(a.XLim(end),mean(a.YLim),sprintf(' %s',n{5}),'VerticalAlignment','middle','FontSize',16)
        if mod(ceil(i/4),2)
            %text(a.XLim(end)+1.5*mean(a.XLim),a.YLim(1),sprintf(' %s',n{4}),'VerticalAlignment','middle','FontSize',16)
        end
    end
end

% second row: object stream:
aw=70;
bottom2 = 30;
margin=20;
for j = 1:4
    a=axes('Units','Pixels','Position',[50 bottom2+(aw+margin)*(j-1) aw aw],'Box','on');
    a.XTick=[];a.YTick=[];
    t = {'letters','objects','letters','objects'};    
    text(0,0,{'respond to',t{j}},'HorizontalAlignment','center','VerticalAlignment','middle')
    axis([-1 1 -1 1])
    
    a=axes('Units','Pixels','Position',[50+aw*(8) bottom2+(aw+margin)*(j-1) aw aw],'Box','on');
    a.XTick=[];a.YTick=[];   
    text(0,0,'- - -','HorizontalAlignment','center','VerticalAlignment','middle')
    axis([-1 1 -1 1])
    
end

stims = [4 0 14 0 5 0 14];
stims2 = [1 0 15 0 1 0 4];
rng(1);
for j=1:4
    letterstimuli = 'ABCDEFGJKLQRTUVY';

    for i=1:length(stims)
        a=axes('Units','Pixels','Position',[50+aw*i bottom2+(aw+margin)*(j-1) aw aw],'Box','on','YDir','reverse');
        
        ss = [1 2 57 2 63 2 53];
        fn = sprintf('screenshots_exp%i/screen_%05i.png',1+(j<3),ss(i));
        im = imread(fn);
        im = im(275:425,275:425,:);
        image('XData',[1 200],'YData',[1 200],'CData',im);       
        
%         if mod(i,2)
%             image(im{stims(i)},'AlphaData',alpha{stims(i)});
%             w=51;
%             r=rectangle('Position',[112-.5*(w-1),112-.5*(w-1),w,w],'Curvature',[1,1], 'FaceColor','w','EdgeColor','w');
%             text(112,112,letterstimuli(stims2(i)),'HorizontalAlignment','center','VerticalAlignment','middle')
%         else
%             w=11;
%             r=rectangle('Position',[112-.5*(w-1),112-.5*(w-1),w,w],'Curvature',[1,1], 'FaceColor','k','EdgeColor','k');
%         end
        axis([0 201 0 201])
        a.XTick=[];a.YTick=[];
        if j>0
            tx = text(mean(a.XLim),max(a.YLim),'200ms','HorizontalAlignment','center','VerticalAlignment','top');
            if ~mod(j,2) && i==5 || mod(j,2) && i==7
                tx.Color = 'r';
            end
        end
    end
end
%add arrows and text
ar=[ annotation('line','Units','pixels','Position',[50+5*aw1 bottom+4*aw1 -30 30]),...
	 annotation('line','Units','pixels','Position',[50+5*aw1 bottom+4*aw1 -30 -30]),...
	 annotation('line','Units','pixels','Position',[50+5*aw1 bottom+2*aw1 -30 30]),...
	 annotation('line','Units','pixels','Position',[50+5*aw1 bottom+2*aw1 -30 -30]),...
];set(ar,'Color','k','LineWidth',2);
at=[ annotation('textbox','String','animals','Units','pixels','Position',[55+5*aw1 bottom+4*aw1 0 0]),...
     annotation('textbox','String','vehicles','Units','pixels','Position',[55+5*aw1 bottom+2*aw1 0 0]),...
	 annotation('textbox','String','birds','Units','pixels','Position',[55+4*aw1 bottom+4.5*aw1 0 0]),...
     annotation('textbox','String','fish','Units','pixels','Position',[55+4*aw1 bottom+3.5*aw1 0 0]),...
     annotation('textbox','String','boats','Units','pixels','Position',[55+4*aw1 bottom+2.5*aw1 0 0]),...
     annotation('textbox','String','planes','Units','pixels','Position',[55+4*aw1 bottom+1.5*aw1 0 0]),...
];set(at,'FontSize',16,'VerticalAlignment','middle');
% ar=[ annotation('arrow','Units','pixels','Position',[50+aw*7.5 bottom+(aw+margin)+40+aw 0 -40]),...
% 	 annotation('arrow','Units','pixels','Position',[50+aw*5.5 bottom-40 0 40]),...
% ];set(ar,'Color','k','LineWidth',10,'HeadWidth',40,'HeadLength',20,'HeadStyle','plain');
at=[ annotation('textbox','String','A','Units','pixels','Position',[10 bottom+5*aw1-33 0 0]),...
     annotation('textbox','String','B','Units','pixels','Position',[10 bottom2+3*(aw+margin)+40 0 0]),...
	 annotation('textbox','String','C','Units','pixels','Position',[10 bottom2+2*(aw+margin)+40 0 0]),...
	 annotation('textbox','String','D','Units','pixels','Position',[10 bottom2+1*(aw+margin)+40 0 0]),...
	 annotation('textbox','String','E','Units','pixels','Position',[10 bottom2+0*(aw+margin)+40 0 0]),...
];set(at,'FontSize',30,'VerticalAlignment','bottom');

%% save
fn = 'figures/figure_design';
tn = tempname;
print(gcf,'-dpng','-r500',tn)
im=imread([tn '.png']);
[i,j]=find(mean(im,3)<255);margin=2;
imwrite(im(min(i-margin):max(i+margin),min(j-margin):max(j+margin),:),[fn '.png'],'png');
