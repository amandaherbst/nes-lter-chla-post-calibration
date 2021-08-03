clearvars, clc, close all


%Set the directory
rep = '/Users/amandaherbst/Documents/MATLAB/SURFO/';
%URL of the REST-API
RESTAPI='https://nes-lter-data.whoi.edu/api/';
%cruise selection
CRUISE={'en644';'en649';'en655';'en657';'en661';'en668'};

%Set the weboptions for downloading files as table
options = weboptions('ContentType', 'table');


for n1=1:length(CRUISE)
        
    %Get the data from the en6XX.csv files stored on the REST-API
    tablename1 = strcat(RESTAPI,'underway/',CRUISE{n1},'.csv');
    table_uw = webread(tablename1, options);
    
    %Convert the date string into datenum
    iso8601format = 'yyyy-mm-dd hh:MM:ss';
    Time_UW = datenum(table_uw.date, iso8601format);
    
    %Get the Latitude, Longitude, Fluo1/Fluo2 in Volt and in ug/L from the table
    Latitude=table_uw.gps_furuno_latitude;
    Longitude=table_uw.gps_furuno_longitude;
    Fluo1_v0=table_uw.tsg1_fluorometer1_v0;
    Fluo2_v1=table_uw.tsg1_fluorometer2_v1;
    Fluo1_wetstar=table_uw.tsg1_fluorescence_wetstar;
    Fluo2_ecofl=table_uw.tsg1_fluorescence_ecofl;
    PAR=table_uw.tsg1_spar_calc;
    
    %Get the discrete data from the diescrete underway Chl-a csv files
    tablename2 = strcat(rep,'nes-lter-underway-chla-',CRUISE{n1},'.csv');
    table_discrete=readtable(tablename2);
    
    %Convert the date string into datenum
    Time_discrete=datenum(table_discrete.date_time_utc, iso8601format);
    
    %Create a table to store the exctracted data for each cruise
    %Exact match: 'fluorescence_wetstar_v','fluorescence_ecofl_v',
    %'fluorescence_wetstar','fluorescence_ecofl'
    %Average/StdDev +/-5 min: 'fluorescence_wetstar_vm','fluorescence_wetstar_vstd',...
    %'fluorescence_ecofl_vm','fluorescence_ecofl_vstd',...
    %'fluorescence_wetstar_m','fluorescence_wetstar_std',...
    %'fluorescence_ecofl_m','fluorescence_ecofl_std'
    Results=table('Size',[length(Time_discrete) 21],'VariableTypes',...
        {'categorical','string','double','double','double'...
        ,'string','double','double','double','double','double'...
        ,'double','double','double','double'...
        ,'double','double','double','double','double','double'},...
        'VariableNames',{'cruise','date_time_utc','latitude','longitude','sample_id',...
        'replicate','chl','qc','phaeo','fluorescence_wetstar_v','fluorescence_ecofl_v',...
        'fluorescence_wetstar','fluorescence_ecofl',...
        'fluorescence_wetstar_vm','fluorescence_wetstar_vstd',...
        'fluorescence_ecofl_vm','fluorescence_ecofl_vstd',...
        'fluorescence_wetstar_m','fluorescence_wetstar_std',...
        'fluorescence_ecofl_m','fluorescence_ecofl_std'});
    
    %Find for each discrete data the corresponding lat/lon (exact time),
    %the fluorescence (exact times) 
    for n2=1:length(Time_discrete)
        
        %Find the minimal difference between the sampling time and the
        %underway time
        a1=abs(Time_UW-Time_discrete(n2));
        %Get the position of this minimal time difference
        A1=find(a1==min(a1));
        %Get the matching interval
        A1m=[A1-1;A1;A+1];
        
        %Get the corresponding Lat/Lon and Fluorescence values matching the
        %chosen matching interval
        Results.cruise(n2)=CRUISE(n1);
        Results.date_time_utc(n2)=datestr(Time_discrete(n2),iso8601format);
        Results.latitude(n2)=Latitude(A1);
        Results.longitude(n2)=Longitude(A1);
        Results.sample_id(n2)=table_discrete.sample_id(n2);
        Results.replicate(n2)=table_discrete.replicate(n2);
        Results.chl(n2)=table_discrete.chl(n2);
        Results.qc(n2)=table_discrete.qc(n2);
        Results.phaeo(n2)=table_discrete.phaeo(n2);
        Results.fluorescence_wetstar_v(n2)=Fluo1_v0(A1);
        Results.fluorescence_ecofl_v(n2)=Fluo2_v1(A1);
        Results.fluorescence_wetstar(n2)=Fluo1_wetstar(A1);
        Results.fluorescence_ecofl(n2)=Fluo2_ecofl(A1);
        Results.par(n2)=PAR(A1);
        
        %Average/StdDev fluorescence values 
        Results.fluorescence_wetstar_vm(n2)=nanmean(Fluo1_v0(A1m,1));
        Results.fluorescence_wetstar_vstd(n2)=nanstd(Fluo1_v0(A1m,1));
        Results.fluorescence_ecofl_vm(n2)=nanmean(Fluo2_v1(A1m,1));
        Results.fluorescence_ecofl_vstd(n2)=nanstd(Fluo2_v1(A1m,1));
        
        Results.fluorescence_wetstar_m(n2)=nanmean(Fluo1_wetstar(A1m,1));
        Results.fluorescence_wetstar_std(n2)=nanstd(Fluo1_wetstar(A1m,1));
        Results.fluorescence_ecofl_m(n2)=nanmean(Fluo2_ecofl(A1m,1));
        Results.fluorescence_ecofl_std(n2)=nanstd(Fluo2_ecofl(A1m,1));
        
    end
    
    %Save the Results Table for each cruise and delete the Result table for
    %the next cruise
    tablename = strcat(rep,CRUISE{n1},'_chla_plus_minus_one_matching.csv');
    writetable(Results,tablename)
    
    clear Results
    
end