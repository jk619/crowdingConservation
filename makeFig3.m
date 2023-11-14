clc
clear
close all
addpath(genpath('data'))
addpath(genpath('code'))
addpath(genpath('extra'))

% This script computes the relationship between surface area and number of
% letters with the assumption that conservation holds. It finds the best
% fitting constant of proportionality and asks how much variance in the
% psychophysical data (number of letters) is explained by a simple scaling
% of the surface area.
nboot = 10;
[bouma, area] = crowding_summary_data();

load mycmap

% set this to true if you want to get a sense of null distributions: it
% shuffles the assignment of psychophysical data to brain data

% lower case letters for linear units
a = area';
b = bouma'; clear area bouma;
n = length(b);

% compute number of lettrs from bouma
l = zeros(size(b));

for i = 1 : length(b)
    analytic = crowding_count_letters(b(i),0.24,10,0);
    l(i) = analytic;
    axis off
end



% find linear constants, conservation slope c
for ii = 4:-1:1
    conservation(ii) = a(:,ii) \ l;
end
% predicted number of letters assuming to conservation
pred = a .* conservation;


% formula for coefficient of variation, R2, which ranges from -inf to 1
% R2 = @(data, pred) 1 - sum((pred-data).^2) / sum((data - mean(data)).^2);

% Plot the  fits
ROIs = {'V1' 'V2' 'V3' 'hV4'};


CI_range = 68;
low_prct_range = (100-CI_range)/2;
high_prct_range = 100-low_prct_range;

CI_a_save = NaN(2,4);
CI_r2 = NaN(nboot,4);
convervation = NaN(4,1);
k = NaN(1,4);
myr2 = NaN(4,1);

figure(1);clf
set(gcf, 'color','w', 'Position', [400 400 500 700]); tiledlayout(2,2,'TileSpacing','compact');

for ii = 1:4
    
    nexttile
    
    
    r2 = R2(l, pred(:,ii));
    myr2(ii) = r2;
    xl = [0 max(a(:,ii))*1.05];
    yl = [0 max(l)*1.05];
    
    lm = fitlm(a(:,ii),l);
    k(ii) = lm.Coefficients.Estimate(2); % save slope of the fit as k
    lmpred = lm.Coefficients.Estimate(1)+ lm.Coefficients.Estimate(2)*xl;
    
    data = [a(:,ii) l pred(:,ii)];
    fitresult_ls = bootstrp(nboot,@give_a_b_r,data);
    
    
    CI_a=prctile(fitresult_ls(:,2), [low_prct_range, high_prct_range]);
    CI_b=prctile(fitresult_ls(:,1), [low_prct_range, high_prct_range]);
    CI_a_save(:,ii) = CI_a;
    CI_r2(:,ii)=fitresult_ls(:,3);
    
    
    X = linspace(min(a(:,ii)),max(a(:,ii)),100);
    y = zeros(100,nboot);
    
    for i = 1:nboot
        
        y(:,i)=fitresult_ls(i,2)*X + fitresult_ls(i,1);
        
    end
    
    
    CI_y=prctile(y, [low_prct_range, high_prct_range],2);
    
    set(gca, 'FontSize', 15)
    fprintf('V%d : R^2=%3.2f,\t conservation = %3.2f letters/mm^2,\tk = %.2f letters/mm^2\n', ii, r2, conservation(ii),k(ii))
    
    axis([xl yl])
    
    hold on,
    plot(xl, conservation(ii) * xl, 'k--', 'LineWidth', 1)
    plot(xl, lmpred, '-', 'Color', mycmap{ii}(2,:), 'LineWidth', 3);
    plot(X,CI_y,'--','linewidth',2,'Color', mean(mycmap{ii}))
    g = gca;
    g.XAxis.LineWidth = 1;
    g.YAxis.LineWidth = 1;
    s = scatter(a(:,ii), l,  'MarkerFaceColor',mycmap{ii}(2,:), 'MarkerEdgeColor', 'k');
    s.MarkerFaceAlpha = 1;
    s.MarkerEdgeColor = mycmap{ii}(2,:);
    s.SizeData = 20;
    
    s_ex = scatter(a([2 9],ii), l([2 9]), 'MarkerFaceColor',[0.5 0.5 0.5], 'MarkerEdgeColor', 'k','Marker','.');
    
    hold off
    t=title(ROIs{ii});
    t.Units = 'normalized';
    t.Position = [0.2 0.85 0];
    myx = xlim;
    
    if ii == 4
        text(min(a(:,ii))+0.03*myx(2),100,sprintf('\\rm\\itc\\rm = %.1f mm',round(1/sqrt(k(ii)),2)),'FontSize',20,'FontWeight','bold','horizontalalignment','left','Color',[0 0 0])
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
    
    %     hgexport(gcf, sprintf('../figures/conservation_fit_%s.eps', str));
    drawnow
end
set(gcf, 'color','w', 'Position', [400 400 500 700]);

figure(2);clf
set(gcf, 'color','w', 'Position', [900   400   500   700]);

subplot(2,2,4)
xs = [1 2 3 4];
CI_r2_vals=prctile(CI_r2, [low_prct_range, high_prct_range]);
CI_r2_toplot = abs(CI_r2_vals - median(CI_r2_vals));

for r = 1 : 4
    
    color = mean(mycmap{r});
    hold on
    b =  bar(xs(r), myr2(r),'FaceColor',[0 0 0],'Edgecolor',[0 0 0],'LineWidth',2);
    er = errorbar(xs(r), myr2(r),CI_r2_toplot(1,r),CI_r2_toplot(2,r),'linestyle','--','Color',[0.5 0.5 0.5],'LineWidth',4,'CapSize',0);
    
end

xticks(xs)
ylim([-0.3  0.6])
yticks([-0.2 0 0.2 0.4 0.6 0.8])

xticklabels(ROIs)
set(gca,'Fontsize',18);
xlim([0 4.5])
box off
g = gca;
g.YAxis.LineWidth = 1;
g.XAxis.LineWidth = 1;




function [fitresults] = give_a_b_r(data)

lm = fitlm(data(:,1),data(:,2));
r2 = R2(data(:,2),data(:,3));
fitresults = [lm.Coefficients.Estimate(1) lm.Coefficients.Estimate(2) r2];

end


function out_R2 = R2(data, pred)

out_R2 = 1 - sum((pred-data).^2) / sum((data - mean(data)).^2);

end
