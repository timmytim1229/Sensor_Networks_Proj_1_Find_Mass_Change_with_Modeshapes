function [mass,AverageMass,Delta]=CalculateDeltaMass(type)


%% SDOF ACCELERATION
% Objective: Import accelerometer data and plot acceleration vs. time

%% Import Accelerometer Data

%Open Serial Port
serDev = serial('COM5','BaudRate',9600);
fopen(serDev);

%Collect some number of sample points
%Sample rate ~ 160.5 Hz (according to tic - toc)
SampleSize = 1500; 

%Define Array sizes with Zeros()
%So the size doesnt change during the loop.
t = zeros(1,SampleSize); %Cumulative Time
SingleSampleTime = zeros(1,SampleSize); %Time to aqcuire single data point
Acceleration = zeros(1,SampleSize); 
 
%Use try/catch statement to ensure ports are always closed/deleted
try 
    for i = 1:SampleSize
        tic
        fscanf_Result = fscanf(serDev,'%d'); %Raw acceleration data
        Acceleration(i) = (fscanf_Result*3.3/4096)/0.33; %Convert to g's
        SingleSampleTime(i) = toc; %time for single data point
    end
    
    %cumulative time calc
    CumulativeT=zeros(1,length(SingleSampleTime));
    CumulativeT(1) = SingleSampleTime(1);
    for i = 2:length(SingleSampleTime)
       CumulativeT(i) = CumulativeT(i-1)+SingleSampleTime(i);
    end
    
    MeanAccel = mean(Acceleration);
    ShiftedAcceleration = Acceleration - MeanAccel;
       
    %Average time for single sample
    TimePerSample = mean(SingleSampleTime);
    
    %Total sample time
    TotalTime = sum(SingleSampleTime);
    
    %--------------------------------------------------------
    %Name figure
    %figure('name','Accelerometer Data','NumberTitle','off')
    %--------------------------------------------------------
    
    
    %Use builtin smoothing function to reduce noise
    SmoothFun = smooth(ShiftedAcceleration);
    
    %Remove first data points due to abnormal data.
    tClean = CumulativeT(5:length(CumulativeT));
    AccelerationClean = ShiftedAcceleration(5:length(ShiftedAcceleration));
    SmoothFunClean = SmoothFun(5:length(SmoothFun));
    SmoothFunClean = smooth(SmoothFunClean);
    
    %--------------------------------------------------------
    %Plot acceleration in g's
    %Plot smoothed function

    
    plot(tClean,AccelerationClean,'--k')
    hold on
    gvfbn                  
    %hold on 
    %plot(tClean,smooth(SmoothFunClean),'--b')
    xlabel('Time (s)')
    ylabel('Acceleration (G)')
    legend('Acceleration','Smooth Acceleration')
    hold on
    %--------------------------------------------------------
    
    %% Find Local Maxima
    %findpeaks is a builtin matlab function
    %Which finds every local maxima
    [Peaks,locs] = findpeaks(SmoothFunClean);
    
    %locs (location of Peaks) is given as an index in X. 
    %Convert index to actual position
    PeaksTime = CumulativeT(locs+4); % 4 accounts for shift of data.
    
    %% Focus on ONLY Vibrational System (Ignore other local maxima)

    %Set AllPeaks = Peaks so we can manipulate this new 
    %variable so we can remove max values from the array 
    %as we find each overall max value.
    AllPeaks = Peaks;
     
    %Find which 12 local maxima are the largest
    TotalPeakValues = 12;
    MaxPeaks = zeros(1,TotalPeakValues);
    MaxIndex = zeros(1,TotalPeakValues);
    
    for i = 1:TotalPeakValues
       [MaxPeaks(i), MaxIndex(i)] = max(AllPeaks);
       AllPeaks(MaxIndex(i)) = 0;      
    end
    
    %Filter irrelevant peaks
    PreviousLargestIndex = MaxIndex(1);
    CleanMaxIndex = MaxIndex;
    CleanMaxPeaks = MaxPeaks;
    
    for i = 2:length(MaxIndex)
        
        if MaxIndex(i)<MaxIndex(i-1)
            %The index is on a irrelevant peak
            CleanMaxIndex(i) = [];
            CleanMaxPeaks(i) = [];
        end
        
    end
    
    TimeOfSystemPeaks = PeaksTime(CleanMaxIndex); %(MaxIndex);
    
    %--------------------------------------------------------
   
    plot(TimeOfSystemPeaks,CleanMaxPeaks,'*')
    legend('Acceleration','Smooth Acceleration','Local Maxima');    

    %--------------------------------------------------------
    
    %% Calculate Mass
    %Determine Damping Ratio 
    %Select 2nd and 6th peak
    i = 2;
    j = 6;

    U1=MaxPeaks(i); %Use second peak instead of first peak
    U2=MaxPeaks(j); %Use sixth peak

    %Determine Damping Ratio (Zeta)
    Delta = (1/(j-i))*log(U1/U2);
    %Delta = 2*pi*Zeta
    Zeta = Delta/(2*pi); % Zeta = Damping Ratio

    %Experimentally determine k
    k = 46.3; %N/m

    %Damped Natural Period/ Damped Natural Freq - analyze graph
    %determine average period between several peaks
    %Averaging across several periods improves accuracy
    DampedNatPeriod = (TimeOfSystemPeaks(j)-TimeOfSystemPeaks(i))/(j-i); %s
    DampedNatFreq = (2*pi)/DampedNatPeriod; %Rad/s

    %Natural Freq
    NatFreq = DampedNatFreq/(sqrt(1-(Zeta^2))); %Rad/s

   

        %Determine Mass
        mass = k/(NatFreq^2) % kg

        %% Save mass to csv to average
        if type == 'U' %Undamaged
            fileName = 'massUndamaged.csv';
        else
            fileName = 'massDamaged.csv';
        end

        CheckMassFileExist = exist(fileName);
        if CheckMassFileExist == 2 %If the .csv file exists, then...
            MassArray = dlmread(fileName);
            MassArray = [MassArray,mass]; %Append .csv with new mass
            dlmwrite(fileName,MassArray) %save .csv file
        else
            csvwrite(fileName,mass)
        end
        MassArray = csvread(fileName);
        AverageMass = mean(MassArray);

        if type == 'D'
            DamagedMassMean = mean(dlmread('massDamaged.csv'))
            UndamagedMassMean = mean(dlmread('massUndamaged.csv'))
            Delta = UndamagedMassMean - DamagedMassMean


        else
            Delta = [];
        end

%{
    %% Double Integration & Plot Position
    FilteredAccelData = ShiftedAcceleration; %SmoothFunClean;
    
    Velocity = cumtrapz(tClean,FilteredAccelData);
    ApproxPosition = cumtrapz(tClean,Velocity);

    figure('name','Position Data','NumberTitle','off');
    plot(tClean,ApproxPosition);
%}
    
    %{
%%Create Theoretical model
    
%% Problem 3: SDOF Model

%% Define Variables
z = 0.02; %Damping ratio
wd_RISA = 2.347; %rad/s - Determined from RISA model 
%uo - initial displacement
%uDot - initial velocity
wn_RISA = wd_RISA/(sqrt(1-z^2)); % Back out Wn from Wd from RISA model.
tTheory = linspace(0,3,1000);

%% Scenario: Initial Velocity = 0, Initial Displacement = 1 in
S1 = Problem3_SDOF(tTheory,z,wn_RISA,wd_RISA,0,1);
figure('name','SDOF Vibration Model','NumberTitle','off')
plot(tTheory,S1,'k')
xlabel('Time')
ylabel('Position')
   %}
catch
    fclose(serDev);
    delete(serDev);
    return
end

%close/delete serial connection
fclose(serDev);
delete(serDev);