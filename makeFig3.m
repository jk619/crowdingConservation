
% This script computes the relationship between surface area and number of
% letters with the assumption that conservation holds. It finds the best
% fitting constant of proportionality and asks how much variance in the
% psychophysical data (number of letters) is explained by a simple scaling
% of the surface area.


clc
clear
close all

[directory,~] = fileparts(mfilename('fullpath'));
cd(directory);
addpath(genpath('data'))
addpath(genpath('code'))
addpath(genpath('extra'))
ROIs = {'V1' 'V2' 'V3' 'hV4'};
load mycmap
load subjects_ID.mat

% number of bootstraps for calculating CIs
nboot = 1000;
% load data
two_sess = 0;
[bouma, area] = load_from_raw('midgray',two_sess);

l = zeros(size(bouma));

for i = 1 : length(bouma)
    analytic = crowding_count_letters(bouma(i),0.24,10,0);
    l(i) = analytic;
    axis off
end

CI_range = 68;
low_prct_range = (100-CI_range)/2;
high_prct_range = 100-low_prct_range;

CI_r2 = NaN(nboot,4);
convervation = NaN(4,1);
m = NaN(1,4);
myr2 = NaN(4,1);

figure(1);clf
set(gcf, 'color','w', 'Position', [400 400 500 700]); tiledlayout(2,2,'TileSpacing','compact');

% Plot the  fits

for ii = 1:length(ROIs)
    
    nexttile
    
    area_roi = area(:,ii);
    % find slope of conservation (0 intercept)
%     conservation = area_roi \ l;
%     % find number of letters preficted by conservation
%     pred = area_roi .* conservation;
%     % find how much variance is explained by conservation
%     r2 = R2(l, pred);
%     myr2(ii) = r2;
%     
%     
    xl = [0 max(area_roi)*1.05];
    yl = [0 max(l)*1.05];
%     
%     lm = fitlm(area_roi,l);
%     m = lm.Coefficients.Estimate(2); 

    data(:,1) = area_roi;
    data(:,2) = l;
    fitresult_ls = bootstrp(nboot,@give_a_b_r,data);
    lmpred = nanmedian(fitresult_ls(:,1))+ nanmean(fitresult_ls(:,2))*xl;
    conservation = nanmedian(fitresult_ls(:,5));
    
    CI_a=prctile(fitresult_ls(:,2), [low_prct_range, high_prct_range]);
    CI_k=prctile(fitresult_ls(:,5), [low_prct_range, high_prct_range]);
    CI_b=prctile(fitresult_ls(:,1), [low_prct_range, high_prct_range]);
    CI_r2(:,ii)=fitresult_ls(:,3);

    
    set(gca, 'FontSize', 15)
    fprintf('|-------------V%i--------------|\n',ii);
    fprintf('  k   = %.2f [%.2f %.2f]\n',median(fitresult_ls(:,5)),(CI_k));
    fprintf('  b   = %.2f [%.2f %.2f]\n',median(fitresult_ls(:,1)),CI_b);
    fprintf('  R^2 = %.2f [%.2f %.2f]\n',median(fitresult_ls(:,3)),prctile(fitresult_ls(:,3), [low_prct_range, high_prct_range]));
    fprintf('  c   = %.2f [%.2f %.2f]\n',sqrt(1/median(fitresult_ls(:,5))),fliplr(1./sqrt(CI_k)));
    fprintf('|-----------------------------|\n\n');

    
    
    axis([xl yl])
    
    hold on,
    plot(xl, conservation * xl, 'k--', 'LineWidth', 1)
    plot(xl, lmpred, '-', 'Color', mycmap{ii}(2,:), 'LineWidth', 3);
    
    g = gca;
    g.XAxis.LineWidth = 1;
    g.YAxis.LineWidth = 1;

    
    s = scatter(area_roi, l,  'MarkerFaceColor',mycmap{ii}(2,:), 'MarkerEdgeColor', 'k');
    

    s.MarkerFaceAlpha = 1;
    s.MarkerEdgeColor = mycmap{ii}(2,:);
    s.SizeData = 20;
    
    s_ex = scatter(area_roi([2 9]), l([2 9]), 'MarkerFaceColor','k');
    s_ex.SizeData = 60;
    s = scatter(area_roi([2 9]), l([2 9]),  'MarkerFaceColor',mycmap{ii}(2,:), 'MarkerEdgeColor', 'k');
    s.MarkerFaceAlpha = 1;
    s.MarkerEdgeColor = mycmap{ii}(2,:);
    s.SizeData = 20;
    
    t=title(ROIs{ii});
    t.Units = 'normalized';
    t.Position = [0.2 0.85 0];
    myx = xlim;
    
    
    X = linspace(myx(1),myx(2),100);
    y = zeros(100,nboot);
    
    for i = 1:nboot
        
        y(:,i)=fitresult_ls(i,2)*X + fitresult_ls(i,1);
        
    end
    
    
    CI_y=prctile(y, [low_prct_range, high_prct_range],2);
    plot(X,CI_y,'--','linewidth',2,'Color', mean(mycmap{ii}))
    hold off

    
    
    if ii == 4
        text(min(area_roi)+0.03*myx(2),100,sprintf('\\rm\\itc\\rm = %.1f mm',round(1/sqrt(conservation),2)),'FontSize',20,'FontWeight','bold','horizontalalignment','left','Color',[0 0 0])
    end
    
    if ii == 1
        
        t=text(280,110,sprintf('conservation'),'FontSize',12,'FontWeight','normal','horizontalalignment','left','Color',[0 0 0]);
        t.Rotation = 38.5;
    end
    
    if ii == 1
        xticks([0 2000 4000])
        
    elseif ii == 2
        xticks([0 1500 3000])
        
    elseif ii == 3
        xticks([0 1250 2500])
    elseif ii == 4
        
        xticks([0 750 1500])
    end
    
    drawnow
    g = gca;
    g.YAxis.LineWidth = 1;
    g.XAxis.LineWidth = 1;
    g.XColor = [0 0 0];
    g.YColor = [0 0 0];
end

set(gcf, 'color','w', 'Position', [400 400 500 700]);
hgexport(gcf, sprintf('./figures/conservation_fit.eps'));

%% plot R2 with CIs
figure(2);clf
set(gcf, 'color','w', 'Position', [900   400   500   700]);

subplot(2,2,4)
xs = [1 2 3 4];
CI_r2_vals=prctile(CI_r2, [low_prct_range, high_prct_range]);
CI_r2_toplot = abs(CI_r2_vals - median(CI_r2_vals));
CI_r2_median = median(CI_r2_vals);

for r = 1 : 4
    
    color = mean(mycmap{r});
    hold on
    b =  bar(xs(r), CI_r2_median(r),'FaceColor',[0 0 0],'Edgecolor',[0 0 0],'LineWidth',2);
    er = errorbar(xs(r), CI_r2_median(r),CI_r2_toplot(1,r),CI_r2_toplot(2,r),'linestyle','--','Color',[0.5 0.5 0.5],'LineWidth',3,'CapSize',0);
    
end

xticks(xs)
ylim([-0.4  0.6])
yticks([-0.2 0 0.2 0.4 0.6 0.8])

xticklabels(ROIs)
set(gca,'Fontsize',15);
xlim([0 4.5])
box off
g = gca;
g.YAxis.LineWidth = 1;
g.XAxis.LineWidth = 1;
g.XColor = [0 0 0];
g.YColor = [0 0 0];

hgexport(gcf, sprintf('./figures/variance_expl.eps'));

function [fitresults] = give_a_b_r(data)

area = data(:,1);
letters = data(:,2);

lm = fitlm(area,letters);
conservation = area \ letters;
pred = area .* conservation;
r2 = R2(letters,pred);
fitresults = [lm.Coefficients.Estimate(1) lm.Coefficients.Estimate(2) r2 length(unique(data(:,1))) conservation];

end


function out_R2 = R2(data, pred)
% formula for coefficient of variation, R2, which ranges from -inf to 1
% R2 = @(data, pred) 1 - sum((pred-data).^2) / sum((data - mean(data)).^2);

out_R2 = 1 - sumsqr(pred-data) / sumsqr(data - mean(data));

end

