%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Fluorescence Post-Calibration
% Post-calibrates continuous fluorescence data for six cruises with a
% linear regression relationship between discrete and continuous samples
% Inputs: RESTAPI Underway, en6xx_uw_discrete_cont_match.csv
% Outputs: en6xx_post_cal_fluo.csv
% Authors: Amanda Herbst, Pierre Marrec
% Created on 08/06/2021
% Updated on 08/11/2021
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clearvars, clc, close all

%Set the directory
rep = '/Users/amandaherbst/Documents/MATLAB/SURFO/';
%URL of the REST-API
RESTAPI='https://nes-lter-data.whoi.edu/api/';
%cruise selection
cruise={'en644';'en649';'en655';'en657';'en661';'en668'};
%Set the weboptions for downloading files as table
options = weboptions('ContentType', 'table');

for i1=1:length(cruise)
    
    %Get the data from the en6XX.csv files stored on the REST-API
    tablename1 = strcat(RESTAPI,'underway/',cruise{i1},'.csv');
    table_uw = webread(tablename1, options);
    
    iso8601format = 'yyyy-mm-dd hh:MM:ss';
    Time_UW = datenum(table_uw.date, iso8601format);
    
    % Get underway data in csv files created from code to match chl-a and
    % fluorescence
    filename1=strcat(cruise{i1},'_uw_discrete_cont_match.csv');
    table1 = readtable(filename1);
    table1.time_discrete = datestr(table1.date_time_utc, iso8601format);
    table1.time_discrete = datenum(table1.time_discrete, iso8601format);
    
    % only use discrete data with quality control flag = 1
    a=find(table1.iode_quality_flag==1);
    chl1=table1.chl(a);
    fluo_wetstar1 = table1.fluorescence_wetstar_match(a);
    fluo_ecofl1 = table1.fluorescence_ecofl_match(a);
    
    n = length(chl1(~isnan(chl1)));
    
    % Find linear fit model
    
    if i1==1  % use ecofl for en644 and wetstar for rest of the cruises
        model1=fitlm(fluo_ecofl1,chl1);
        a1=linspace(0,max(fluo_ecofl1),100)';
        
    else
        model1 = fitlm(fluo_wetstar1,chl1);
        a1 = linspace(0,max(fluo_wetstar1),100)';
    end
    
    rsq1 = model1.Rsquared.Ordinary; %R^2
    m1 = model1.Coefficients.Estimate(2); % slope
    b1 = model1.Coefficients.Estimate(1); % y-intercept
    [ypred1,yci1]=predict(model1,a1);
    residuals=model1.Residuals.Raw;
    A=nanmean(residuals); % mean of residuals
    B=nanstd(residuals); % std dev of residuals
    
    % Calibrate continuous fluorescence data
    if i1==1
        calibrated_fluorescence = table_uw.tsg1_fluorescence_ecofl*m1+b1;
    else
        calibrated_fluorescence = table_uw.tsg1_fluorescence_wetstar*m1+b1;
    end
    
    % find index of when fluo is number, not NaN
    f=~isnan(calibrated_fluorescence);
    F=find(f==1);
    Start=F(1);
    End=F(end);
    
    % define length of table for each cruise
    table_length=length(Start:End);
    
    %Create a table to store the post-calibrated data for each cruise
    Results=table('Size',[table_length 9],'VariableTypes',...
        {'categorical','string','double','double','double'...
        ,'double','double','double','double'},...
        'VariableNames',{'cruise','date_time_utc','latitude','longitude',...
        'depth','fluorescence_post_cal','fluorescence_manufacturer_cal',...
        'iode_quality_flag','preferred_fluorometer'});
    
    %Start by setting all the QC flags to 1=good
    Results.iode_quality_flag=ones(table_length,1);
    
    for i2=1:table_length
        Results.cruise(i2)=cruise(i1);
        %Set up the QC flag to 3=questionable to the first and last 5min
        C1=i2<=5;
        if C1==1
            Results.iode_quality_flag(i2)=3;
        else
        end
        C2=i2>=(table_length-4);
        if C2==1
            Results.iode_quality_flag(i2)=3;
        else
        end
        
        % First 2 days of en661 cruise will be considered as 3=questionable,
        %more detailed  in the ReadMe file
        if i1==5
            TIME=Time_UW(Start:End);
            C3=TIME(i2)<=datenum(2021,2,5,9,22,0);
            if C3==1
                Results.iode_quality_flag(i2)=3;
            else
            end
        else
        end
        % Any NaN data will be considered as 9=missing data
        CAL=calibrated_fluorescence(Start:End);
        C4=isnan(CAL(i2));
        if C4==1
            Results.iode_quality_flag(i2)=9;
        else
        end
        % Any negative values will be considered as 4=bad data
        C5=find(CAL(i2)<0);
        if C5==1
            Results.iode_quality_flag(i2)=4;
        else
        end
        
    end
    
    Results.date_time_utc=datestr(Time_UW(Start:End),iso8601format);
    Results.latitude=table_uw.gps_furuno_latitude(Start:End);
    Results.longitude=table_uw.gps_furuno_longitude(Start:End);
    Results.depth=repmat(5,table_length,1);
    Results.fluorescence_post_cal=calibrated_fluorescence(Start:End);
    
    if i1==1 %for en644 the prefered fluorometer is 2 = ECOFL
        Results.fluorescence_manufacturer_cal=table_uw.tsg1_fluorescence_ecofl(Start:End);
        Results.preferred_fluorometer=repmat(2,table_length,1);
    else %for the other cruises, the prefered fluoroemeter is 1 = WetStar
        Results.fluorescence_manufacturer_cal=table_uw.tsg1_fluorescence_wetstar(Start:End);
        Results.preferred_fluorometer=ones(table_length,1);
    end
    
    tablename = strcat(rep,cruise{i1},'_post_cal_fluo.csv');
    writetable(Results,tablename)
    
end