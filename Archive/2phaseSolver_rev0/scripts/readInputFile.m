%
% usage: structure=readInputFile(filename)
%
% read formatted file
%
% ============================ INPUT =====================================
% Variable       |   Format            | Unit  |     Description
% ------------------------------------------------------------------------
% filename       |  string             | N/A   | formatted file
% ------------------------------------------------------------------------
%
% ============================ OUTPUT ====================================
% Variable       |   Format            | Unit  |     Description
% ------------------------------------------------------------------------
% structure      | array:structure     | N/A   | data from formatted file
% ------------------------------------------------------------------------
%
% To be reviewed and improved
% For instance: allow flexibility in input files (arbitrary field specifications)
%

function structure=readInputFile(filename)

fid=fopen(filename);
if fid==-1
   error('ADAM:readInputFile:fileNotFound',...
   '%s',['could not open file ' filename]);
end

structure=[];                                                              % Initialization

R=fgetl(fid);                                                              % Read first line
while R~=-1                                                                % Read until EOF
   foo=deblank(R);
   if isempty(foo)
      R=fgets(fid);
      continue
   end
   if strcmp(foo(1),'!') || strcmp(foo(1),'\n')
      R=fgets(fid);
      continue
   end

   keywords={};
   values={};

   while ~strcmp(R(~isspace(R)),'END')                                     % Continue until end of block
      [T,R]=strtok(R);                                                     % First token is assumed to be the keyword
      if isempty(deblank(T)) || strcmp(T(1),'!')
         R=fgetl(fid);
         continue
      end
      keywords=[keywords {upper(T)}];
      while T(end)~='>'                                                    % Ignore everything until '>' is found
         [T,R]=strtok(R);
      end

      value=sscanf(R,'%f')';                                               % Is there any numerical data?
      if isempty(value)
         value=sscanf(R,'%s');                                             % If not, look for a  string
      end
      if isempty(value)                                                    % If no data after '>' it probably is on the next line
         value=[];
         R=fgetl(fid);                                                     % Then read data from next line
         while ~isempty(sscanf(strtok(R),'%f'))                            % Until a new keyword is found
            value=[value sscanf(R,'%f')'];                                 % Concatenate value vector
            R=fgetl(fid);
         end
         values=[values {value}];                                          % Store data
         continue                                                          %  and start again
      end
      values=[values {value}];                                             % If everything on one line, store data and continue
      R=fgetl(fid);
   end

   structure=[structure cell2struct(values,keywords,2)];
   R=fgets(fid);                                                           % Read first line of next point
end

fclose(fid);
