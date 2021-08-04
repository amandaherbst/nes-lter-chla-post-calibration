clc
clear all

% set path
addpath '/Users/amandaherbst/Documents/MATLAB/SURFO'
% Cruise selection
cruise={'en644';'en649';'en655';'en657';'en661';'en668'};

for i1=6:length(cruise)
    
    % Get underway data in csv files created from code to match chl-a and
    % fluorescence
    filename1=strcat(cruise{i1},'_chla_plus_minus_one_matching.csv');
    table1 = readtable(filename1);
    
    %Get only data values with a QC=1
    a=find(table1.qc==1);
    chl1=table1.chl(a);
    fluo_wetstar1 = table1.fluorescence_wetstar_m(a);
    fluo_ecofl1 = table1.fluorescence_ecofl_m(a);
    par1 = table1.par(a);
    
    n = length(chl1(~isnan(chl1)));
    
    % linear fit model for wetstar
    model1 = fitlm(fluo_wetstar1,chl1);
    rsq1 = model1.Rsquared.Ordinary; % R^2
    m1 = model1.Coefficients.Estimate(2); % slope
    b1 = model1.Coefficients.Estimate(1); % y-intercept
    
    %Confidence Interval wetstar
    a1 = linspace(0,max(fluo_wetstar1),100)';
    [ypred1,yci1]=predict(model1,a1);
    
    % Find linear fit model for ecofl
    model2 = fitlm(fluo_ecofl1,chl1);
    rsq2 = model2.Rsquared.Ordinary; % R^2
    m2 = model2.Coefficients.Estimate(2); % slope
    b2 = model2.Coefficients.Estimate(1); % y-intercept
    
    % Confidence Interval ecofl
    a2 = linspace (0,max(fluo_ecofl1),100)';
    [ypred2,yci2]=predict(model2,a2);
    
    % plot linear regression WETSTAR
    figure
    plot(a1,ypred1,'k-')
    hold on
    % Plot confidence interval
    plot(a1,yci1(:,1),'--','LineWidth',1,'Color','k')
    plot(a1,yci1(:,2),'--','LineWidth',1,'Color','k')
    % Plot actual data points and color with PAR
    scatter(fluo_wetstar1,chl1,70,log(par1),'filled','MarkerEdgeColor','k','LineWidth',1);
    colormap gray
    caxis([1 1000]);
    c1=[0.01 0.1 1 10 100 1000];
    caxis(log([c1(1) c1(length(c1))]));
    cbar1 = colorbar('location','EastOutside','FontSize',20,'YTick',log(c1),'YTickLabel',c1);
    ylabel(cbar1,'PAR (\mumol photons m^-^2 s^-^1)','FontSize',15,'Rotation',90);
    xlabel('Fluorescence (r.f.u.)');
    ylabel('Discrete Chl-a (\mug L^-^1)');
    ylim([0 ceil(max(chl1))]);
    ax1=gca;
    ax1.TickDir='both';ax1.XMinorTick='on';ax1.YMinorTick='on';
    ax1.FontSize=15; ax1.FontName='Arial';
    box on
    ax1.LineWidth=1;
    % Label plot with R^2, number of data points, and regression equation
    % If intercept is negative, no "+" in the regression equation
    if b1<0
        text((max(fluo_wetstar1)*.25),(max(chl1)*.9),...
            {strcat('R^2 = ',num2str(rsq1,'%.2f'))
            strcat('n = ',num2str(n,'%.0f'))
            strcat('Chl a = ',num2str(m1,'%.2f'),' * Fluo ',num2str(b1,'%.2f'))},...
            'HorizontalAlignment','left',...
            'FontSize',15)
    else
        text((max(fluo_wetstar1)*.25),(max(chl1)*.9),...
            {strcat('R^2 = ',num2str(rsq1,'%.2f'))
            strcat('n = ',num2str(n,'%.0f'))
            strcat('Chl a = ',num2str(m1,'%.2f'),' * Fluo + ',num2str(b1,'%.2f'))},...
            'HorizontalAlignment','left',...
            'FontSize',15)
    end
    
    figurename1 = strcat('Regression-WETSTAR-',cruise{i1});
    title(figurename1);
    print(figurename1,'-dpng'); % save figure as .png
    
    
    figure
    % plot linear regression ECOFL
    plot(a2,ypred2,'k-')
    hold on
    % plot confidence interval
    plot(a2,yci2(:,1),'--','LineWidth',1,'Color','k')
    plot(a2,yci2(:,2),'--','LineWidth',1,'Color','k')
    % Plot actual data points and color with PAR
    scatter(fluo_ecofl1,chl1,70,log(par1),'filled','MarkerEdgeColor','k','LineWidth',1);
    colormap gray
    caxis([1 1000]);
    c2=[0.01 0.1 1 10 100 1000];
    caxis(log([c2(1) c2(length(c2))]));
    cbar2 = colorbar('location','EastOutside','FontSize',20,'YTick',log(c2),'YTickLabel',c2);
    ylabel(cbar2,'PAR (\mumol photons m^-^2 s^-^1)','FontSize',15,'Rotation',90);
    xlabel('Fluorescence (r.f.u.)');
    ylabel('Discrete Chl-a (\mug L^-^1)');
    ylim([0 ceil(max(chl1))]);
    ax2=gca;
    ax2.TickDir='both';ax2.XMinorTick='on';ax2.YMinorTick='on';
    ax2.FontSize=15; ax2.FontName='Arial';
    box on
    ax2.LineWidth=1;
    %Label plot with R^2, number of data points, and regression equation
    % If intercept is negative, no "+" in the regression equation
    if b2<0
        text((max(fluo_ecofl1)*.25),(max(chl1)*.9),...
            {strcat('R^2 = ',num2str(rsq2,'%.2f'))
            strcat('n = ',num2str(n,'%.0f'))
            strcat('Chl a = ',num2str(m2,'%.2f'),' * Fluo ',num2str(b2,'%.2f'))},...
            'HorizontalAlignment','left',...
            'FontSize',15)
    else
        text((max(fluo_ecofl1)*.25),(max(chl1)*.9),...
            {strcat('R^2 = ',num2str(rsq2,'%.2f'))
            strcat('n = ',num2str(n,'%.0f'))
            strcat('Chl a = ',num2str(m2,'%.2f'),' * Fluo + ',num2str(b2,'%.2f'))},...
            'HorizontalAlignment','left',...
            'FontSize',15)
    end
    
    figurename2 = strcat('Regression-ECOfl-',cruise{i1});
    title(figurename2);
    print(figurename2,'-dpng'); % save figure as .png
    
end