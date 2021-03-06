%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Match underway discrete and continuous data and assigned lat/lon
% Finds the matching continuous underway fluorescence data to the discrete
% underway data based on +/- 1 minute time interval
% Assigned Latitude and Longitude values to each individual sample
% Inputs: RESTAPI Underway, nes-lter-underway-chla-qc-en6xx.csv files
% Outputs: en6xx_uw_discrete_cont_match.csv
% Authors: Amanda Herbst, Pierre Marrec
% Created on 08/05/2021
% Modified on 03/18/2022
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clearvars, clc, close all

%Set the directory
rep = '/Users/pierr/Desktop/NES-LTER_underway_Chla/';
rep1= strcat(rep,'nes-lter-underway-chla-qc_csv_files/');
rep2= strcat(rep,'uw_discrete_cont_match/');
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
    
    %Convert the date string into datenum
    iso8601format = 'yyyy-mm-dd hh:MM:ss';
    Time_UW = datenum(table_uw.date, iso8601format);
    
    %Get the Latitude, Longitude, Fluo1/Fluo2 in ug/L (manufacturer-calibrated) from the table
    Latitude=table_uw.gps_furuno_latitude;
    Longitude=table_uw.gps_furuno_longitude;
    Fluo1_wetstar=table_uw.tsg1_fluorescence_wetstar;
    Fluo2_ecofl=table_uw.tsg1_fluorescence_ecofl;
   
    
    %Get the discrete data from the discrete underway Chl-a csv files
    tablename2 = strcat(rep1,'nes-lter-underway-chla-qc-',cruise{i1},'.csv');
    table_discrete=readtable(tablename2);
    
    %Convert the date string into datenum
    Time_discrete=datenum(table_discrete.date_time_utc, iso8601format);
    
    %Create a table to store the exctracted data for each cruise

    Results=table('Size',[length(Time_discrete) 12],'VariableTypes',...
        {'categorical','string','double','double','double'...
        ,'string','string','double','double','double','double','double'},...
        'VariableNames',{'cruise','date_time_utc','latitude','longitude','depth',...
        'replicate','filter_size','chl','phaeo','iode_quality_flag',...
        'fluo1_wetstar_match','fluo2_ecofl_match'});
    
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
        
        %Get the corresponding Lat/Lon and Fluorescence values matching the
        %chosen matching interval
        Results.cruise(i2)=cruise(i1);
        Results.date_time_utc(i2)=datestr(Time_discrete(i2),iso8601format);
        Results.latitude(i2)=Latitude(A1);
        Results.longitude(i2)=Longitude(A1);
        Results.replicate(i2)=table_discrete.replicate(i2);
        Results.chl(i2)=table_discrete.chl(i2);
        Results.phaeo(i2)=table_discrete.phaeo(i2);
        Results.iode_quality_flag(i2)=table_discrete.qc(i2);
        % Flag NaN chl values with 9 = missing data
        n=isnan(table_discrete.chl(i2));
        if n==1
            Results.iode_quality_flag(i2)=9;
        else
        end
        
        %Average fluorescence values 
        Results.fluo1_wetstar_match(i2)=nanmean(Fluo1_wetstar(A1m,1));
        Results.fluo2_ecofl_match(i2)=nanmean(Fluo2_ecofl(A1m,1));
        
    end
    
    % Add depth and filter size columns 
    Results.depth=repmat(5,length(Time_discrete),1);
    Results.filter_size=repmat(">0",length(Time_discrete),1);
    
    %Save the Results Table for each cruise and delete the Result table for
    %the next cruise
    tablename = strcat(rep2,cruise{i1},'_uw_discrete_cont_match.csv');
    writetable(Results,tablename)
    
    clear Results
    
end