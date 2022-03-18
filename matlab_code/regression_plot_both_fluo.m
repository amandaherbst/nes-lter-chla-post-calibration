%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Plot the calibration curves: Matched Fluo vs. discrete Chl-a
% For each cruise and each fluorometer
% With each colored in fonction of the PAR recorded at the sampling time
% Inputs: RESTAPI Underway, en6xx_uw_discrete_cont_match.csv
% Outputs: Regression-FLUO-en6xx.png (FLUO = ECOfl/WETSTAR depending on the
% fluorometer)
% Authors: Amanda Herbst, Pierre Marrec
% Created on 08/06/2021
% Updated on 03/18/2022
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clearvars, clc, close all

%Set the directory
rep = '/Users/pierr/Desktop/NES-LTER_underway_Chla/';
rep1= strcat(rep,'uw_discrete_cont_match/');
rep2= strcat(rep,'figures/');
%URL of the REST-API
RESTAPI='https://nes-lter-data.whoi.edu/api/';
%Set the weboptions for downloading files as table
options = weboptions('ContentType', 'table');
% Cruise selection
cruise={'en644';'en649';'en655';'en657';'en661';'en668'};

for i1=1:length(cruise)

    %Get the data from the en6XX.csv files stored on the REST-API
    tablename1 = strcat(RESTAPI,'underway/',cruise{i1},'.csv');
    table_uw = webread(tablename1, options);

    %Convert the date string into datenum
    iso8601format = 'yyyy-mm-dd hh:MM:ss';
    Time_UW = datenum(table_uw.date, iso8601format);

    %Get the PAR from the table
    PAR=table_uw.tsg1_spar_calc;

    % Get underway data in csv files created from code to match chl-a and
    % fluorescence
    tablename2=strcat(rep1,cruise{i1},'_uw_discrete_cont_match.csv');
    table1 = readtable(tablename2);

    %Convert the date string into datenum
    Time_discrete=datenum(table1.date_time_utc);

    %Create a vector to store the matched PAR
    PARm=nan(length(Time_discrete),1);
    
    %Find for each discrete data the corresponding lat/lon (exact time),
    %the fluorescence (exact times)
    
    for i2=1:length(Time_discrete)

        %Find the minimal difference between the sampling time and the
        %underway time
        a1=abs(Time_UW-Time_discrete(i2));
        %Get the position of this minimal time difference
        A1=find(a1==min(a1));

        %Get the matching interval
        A1m=[A1-1;A1;A1+1];

        %Get the corresponding PAR value
        PARm(i2)=nanmean(PAR(A1m,1));

    end


        %Get only data values with a QC=1
        a=find(table1.iode_quality_flag==1);
        chl1=table1.chl(a);
        fluo_wetstar1 = table1.fluo1_wetstar_match(a);
        fluo_ecofl1 = table1.fluo2_ecofl_match(a);
        par1 = PARm(a);

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

        figurename1 = strcat(rep2,'Regression-WETSTAR-',cruise{i1});
        titlename1=strcat('Regression-WETSTAR-',cruise{i1});
        title(titlename1);
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

        figurename2 = strcat(rep2,'Regression-ECOfl-',cruise{i1});
        titlename2=strcat('Regression-ECOfl-',cruise{i1});
        title(titlename2);
        print(figurename2,'-dpng'); % save figure as .png

    end