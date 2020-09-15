clear
skipped = 0;
skippedzer = 0;
range = 15;
dims = 4;
statreps = 1;
totreps = 1;

%totreps corresponds to the number of different ABM datasets imported,
%statreps corresponds to the number of times each dataset is computed -
%this is purely for convenience as each result is created and saved before
%the next is computed, and results do not differ if each is computed
%independently or sequentially

ctable = comptable (range, dims);
ressize = ctable (end,end);
fnameprimitive = 'Sim-Results-';
%columnheaders = compressedheaders (range,dims);
%use this line of code to find the behavioral vectors which correspond to
%each row and column of the transition matrix RData. The result should be
%the same size as RData, and each column is the count of that vector within
%the given range. 
for i = 1:totreps
clearvars -except location ctable ressize range dims visionits skipped ...
leadersnum skippedzer totreps statreps fnameprimitive i
location = 0;
its = 8500;
%Import path, must be changed to where data is

currentPath = pwd;
fprintf('------ Input file path: %s\n', fullfile(currentPath, 'SampleTrajectoryData','KenaiSalmonFisheriesABM', 'smdmt(0)sdmt(0)cmdmt(0)cdmt(14)', sprintf('%s%d.txt', fnameprimitive, its)));
importfile = fullfile(currentPath, 'SampleTrajectoryData','KenaiSalmonFisheriesABM', 'smdmt(0)sdmt(0)cmdmt(0)cdmt(14)', sprintf('%s%d.txt', fnameprimitive, its));
testm = uint8 (importwithtime (importfile));
% for its = 1:20
%     importfile = sprintf ('C:\\Users\\Spencer\\documents\\MATLAB\\Netlogo\\%s%d.txt',fnameprimitive, its);
%     testm = padvertcat (testm,uint8(importwithtime (importfile)));
% end

RData = zeros (ressize);
%size(testm,1) = nzmax(RData);
testm = c2vect2 (testm);
%converts the agent by ticks matrix generated by importwithtime into a 2 by
%ticks*agents matrix where x(1,:) is the agent data and x(2,:) is time. 
for its = 1:(size(testm,2)-(range*2))
    %for previous and future of an agent, write event in the result matrix
    %incrementing the value by 1 in the location corresponding to its
    %behavior
    ahist = testm(1,its:its+(range-1));
    if isempty (find (ahist == 0, 1))
        ahist = compmat (ahist,dims);
    else
        continue
    end
    %if there is a 0 in the history or future of an agent, that indicates 
    %a break between one agent's history and the next, which is garbage
    %data and is therefore skipped. This preserves the deliniation between
    %agents
    afut = testm(1,its+range:its+(range*2-1));
    if isempty (find (afut == 0, 1))
        afut = compmat (afut,dims);
    else
        continue
    end
    xcor = compressedindex(ahist,ctable,range,dims);
    ycor = compressedindex(afut,ctable,range,dims);
    prevvalue = RData(ycor,xcor);
    RData(ycor,xcor) = prevvalue + 1;
end

emptyrows = all (~RData,2);
emptyrows = find (emptyrows == 1);
its2 = 1;
while its2 <= statreps
threshold = 0.05;
%The statistical threshold for the chi squared test
chi2L = 1:size(RData);
sums = sum(RData,2);
firstleader = find (sums == max(sums));
firstleader = firstleader (1);
%The first leader is seeded in order to ensure that it is not an extremely
%sparse row of the matrix - which creates problems with the chi square test
%of independence

% %Statistical Correlation
for its3 = 1:size(emptyrows,1)
    x = emptyrows (its3);
    chi2L = chi2L(chi2L ~= x);
end
rmat = zeros(1,size(RData,1))';
%leaders = chi2L (randmat);
leaders = firstleader;
rmat (firstleader) = 1;
followers = 0;
leadercomp = zeros (1,size(RData,1));
chi2L = chi2L (chi2L ~= firstleader);
chis = zeros (2,size(RData,2));
% p2chi = zeros (1,size(RData,2));
while size(chi2L) > 0
    size (chi2L,2)
    randmat = ceil(size(chi2L,2) * rand(1));
    randmat = chi2L(randmat);
    for its = leaders
        chis = [RData(its,:);RData(randmat,:)];
        leadercomp (its) = chisquared(chis);
    end
    [M,I] = max (leadercomp);
    if M > threshold
        followers = followers + 1;
        rmat (randmat) = I;
        chi2L = chi2L (chi2L ~= randmat);
    else
        rmat(randmat) = 1;
        leaders = horzcat (leaders,randmat);   %#ok
        chi2L = chi2L (chi2L ~= randmat);
    end
end

if skipped > 500
    fname = sprintf ('NODATA%s',fnameprimitive);
    exportdata (0,fname);
    continue
end

if size (leaders,2) == 1
    skipped = skipped + 1
    continue
end



clear transmat
location = 0;
floc = 0;
%transmat = sparse (ressize,ressize);
transmat = zeros ((size(testm,2)-(range*2)),3);
for its = 0:(size(testm,2)-((range*2)))
    %for previous and future of an agent, write event in the result matrix
    %incrementing the value by 1
    location = location + 1;
    ahist = testm(1,location:location+(range-1));
    if isempty (find (ahist == 0, 1))
        ahist = compmat (ahist,dims);
    else
        continue
    end
    %if there is a 0 in the history or future of an agent, that indicates 
    %a break between one agent's history and the next, which is garbage
    %data and is therefore skipped
    afut = testm(1,location+range:location+(range*2-1));
    if isempty (find (afut == 0, 1))
        afut = compmat (afut,dims);
    else
        continue
    end
    xcor = compressedindex(ahist,ctable,range,dims);
    ycor = compressedindex(afut,ctable,range,dims);
    if rmat(xcor) ~= 1
        xcor = rmat (xcor);
    end
    if rmat (ycor) ~= 1
        ycor = rmat (ycor);
    end
    if xcor == 0
        skippedzer = skippedzer + 1;
        continue
    end
    if ycor == 0
        skippedzer = skippedzer + 1;
        continue
    end
    %(((location-1)*3)+1:((location-1)*3)+3)
    floc = floc + 1;
    transmat (floc, 1:3) = [xcor,ycor,testm(2,location)];
%     prevvalue = transmat(ycor,xcor);
%     transmat(ycor,xcor) = prevvalue + 1;
end
%fname = sprintf ('%s',fnameprimitive);
transmat (~any(transmat,2),:) = [];
exportdata (transmat,fnameprimitive);
%exportdata is used to export to xls format, such as if the data will be
%used in Gephi. Save is used to save data in the matlab format for easy
%retrieval such as for the MSE_Compare script
transmat = sparse(transmat);
save (fnameprimitive,'transmat');
its2 = its2+1;
end
end
transmat = full(transmat);
%transmat = xytvect2 (transmat);
exportdata (tickwisesave(transmat),'tickwise400switchflocking');
%tickwisesave (transmat,'SwarmingAnalysis')
%MSE_Compare