function data = exportdata(variable,filename)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

currentPath = pwd;
fprintf('------Output file path: %s\n', fullfile(currentPath, 'output', sprintf('%s.csv', filename)));
fname = fullfile(currentPath, 'output', sprintf('%s.csv', filename));
fid = fopen(fname,'w');
dlmwrite (fname,variable);
fclose(fid);
end

