%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% (Semi) Automated Quality Check (QC) of the Discrete Data
%
% Assign automatically a QC flag to the discrete UW Chl-a data based on the
% ratio between the fluorescence before (Fo) and after (Fa) acidification.
% For each cruise, quality check for each individual sample is performed based on the average +/- 1
% Standard Deviation (SD) of the Fo/Fa ratio.
% All individual sample with Fo/Fa value ranged between Mean +/- 1SD are
% assigned with a "1" flag as "good".
% All individual sample with Fo/Fa value ranged out of the Mean +/- 1SD interval are
% assigned with a "3" flag as "questionable/suspect".
% These QC flags follow the IODE Primary Level standards.
%
% Notes:
% Samples acquired during the first 2 days of the en661 cruise are flagged
% as questionable/suspect for the next steps of the post-calibration
% because we knew that the WETStar fluorometer was malfunctioning for 2
% days before it could be cleaned. Meaning that these values could not be
% used for post-calibration.
% The last triplicate of en655 is considered as questionable, because the discrete Chl-a values were
% way too high compared to the recorded fluorescence at this time.
%
% Inputs: nes-lter-underway-chla-en6xx.csv;
% Outputs: nes-lter-underway-chla-en6xx-qc.csv; same csv files as the input
% files, with one extra column for qc flags
% 
% Author: Pierre Marrec
% Created on 03/18/2022
% Updated on 03/18/2022
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clearvars, clc, close all

%Set the directory
rep = '/Users/pierr/Desktop/NES-LTER_underway_Chla/';
rep1 = strcat(rep,'nes-lter-underway-chla_csv_files/');
rep2 = strcat(rep,'nes-lter-underway-chla-qc_csv_files/');

%cruise selection
cruise={'en644';'en649';'en655';'en657';'en661';'en668'};

%Define the date/Time format
iso8601format = 'yyyy-mm-dd hh:MM:ss';

for i1=1:length(cruise)

    %Get the discrete data from the discrete underway Chl-a csv files
    tablename1 = strcat(rep1,'nes-lter-underway-chla-',cruise{i1},'.csv');
    table_discrete=readtable(tablename1);

    % Identify the chla values with FoFa +/- SD
    FoFaAvg=nanmean(table_discrete.fo_fa(:));
    FoFaSD=nanstd(table_discrete.fo_fa(:));
    FoFamin=FoFaAvg-FoFaSD;
    FoFamax=FoFaAvg+FoFaSD;
    a1=find(table_discrete.fo_fa(:)>FoFamin & table_discrete.fo_fa(:)<FoFamax);
    
    %by default all the qc flags set as 3 = questionable
    table_discrete.qc(:)=3;
    %And qc flag = 1 (good) assigned to the values in the +/- 1SD interval
    table_discrete.qc(a1)=1;

    % First 2 days of en661 cruise not included,
    % more detailed  in the header
    Time_UW = datenum(table_discrete.date_time_utc, iso8601format);
    if i1==5
        a0=find(Time_UW<=datenum(2021,2,5,9,22,0));
        table_discrete.qc(a0)=3;
        
    %last triplicate of en655 questimable, way too high compared to the
    %recorded fluorescence
    elseif i1==3
        table_discrete.qc(end-2:end)=3;
    else
    end

    clear a FoFaAvg FoFaSD FoFamin FoFamax

    tablename2=strcat(rep2,'nes-lter-underway-chla-qc-',cruise{i1},'.csv');
    writetable(table_discrete,tablename2)

end


