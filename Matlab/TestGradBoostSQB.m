close all;clc;clear
% load tryLayredNNNew12V1.mat
load all_data_YoloTestAll.mat
prediction_all = [];
%frame number of the first step on the staircase
intension_frames = [193 182 187 221 253 263 171 199 216 187 254 190 232 274 223 120 198 242 238 265 263 225 278 250 158 183 204 192 165 187 173 177 182 175 196 142 196 155 186 301 338 324 319 318 350 292 327 309 365 364 339 176 227 210 348 322 343 209 206 202 216 194 156 197 196 153 220 229 128 241 211 223 187 173 192 155 132 125 153 156 180 191 192 198 174 197 164 191 233 293];
window_size = 0.5; %window size in frames
features = 'Mean_Diff';
features_training = [1,2,4];
for ii = 1: length(features_training)
    features = strcat(features,'_',num2str(features_training(ii)));
end
classifier = 'GradBoostSQB';
%sections = 35;
%ii = 98; %Number of the signal of interest. You can get the number from area_of_BB_all
FPS = 30; %frame per second during video collection
fields_BB = fieldnames(area_of_BB_all);
wrong_class = 0;
samples_in_window = 15;
engage_frame_total = [];
class_change_total = 0;
class_change_details = [];
kk=0;

wrong_class_details = [];
nn = 1;
pp = 1;
% stair2 = 28, stair3 = 47, stair4 = 66, stair5 = 83, stair6 = 93
% for maxVotes = [30 15 10 5]
maxVotes = 15;
for ii = 1:length(fields_BB)
engageOccured = false;
text_file_folder_name = fields_BB{ii};
sep_file_name = strsplit(text_file_folder_name,'_');

temp_var_norm(:,1) = area_of_BB_all.(fields_BB{ii});
temp_var_norm(:,2) = width_all.(fields_BB{ii});
temp_var_norm(:,3) = cent_x_all.(fields_BB{ii});
temp_var_norm(:,4) = cent_y_all.(fields_BB{ii});
temp_window_all=[];
first_time = 1;
class_change = -1;
vote = [];
voteIndex = 1;
stairName = strsplit(sep_file_name{1},'stair');
testStaircase = '34';
if isequal(stairName{2},testStaircase)
% maxVotes = 5;
%get initial votes
for jj = 1:2:length(temp_var_norm)-samples_in_window
    temp_var_norm_window = (temp_var_norm(jj:jj+samples_in_window-1,:));
    [M N] = size(temp_var_norm_window);

    temp_window(1,1:N) = mean(temp_var_norm_window);
    temp_window(1,N+1:2*N) = max(temp_var_norm_window) - min(temp_var_norm_window);
    
    stairName = strsplit(sep_file_name{1},'stair');
    load(strcat(pwd,'\',features,'\', num2str(samples_in_window),'\',classifier,stairName{2},'.mat'));

    test.X = temp_window(:,features_training);
    prediction = SQBMatrixPredict( trainedModel, single(test.X) );
    if prediction <0
        vote(voteIndex) = 0;
        voteIndex = voteIndex + 1;
    else
        vote(voteIndex) = 1;
        voteIndex = voteIndex + 1;
    end
    if voteIndex > maxVotes
        break;
    end
    clear temp_window;
end

currentjj = jj;
if voteIndex > maxVotes
    %for jj = 1:samples_in_window:length(temp_var_norm)-samples_in_window
    for jj = 1:2:length(temp_var_norm)-samples_in_window
    %     first_section = sections;
    %     last_section = length(temp_var_norm) - first_section;
        temp_var_norm_window = (temp_var_norm(jj:jj+samples_in_window-1,:));
        [M N] = size(temp_var_norm_window);

        temp_window(1,1:N) = mean(temp_var_norm_window);
        temp_window(1,N+1:2*N) = max(temp_var_norm_window) - min(temp_var_norm_window);
        
        stairName = strsplit(sep_file_name{1},'stair');
        load(strcat(pwd,'\',features,'\', num2str(samples_in_window),'\',classifier,stairName{2},'.mat'));
        if isequal(features,'Mean')
            test.X = temp_window(:,1:2);
            prediction = SQBMatrixPredict( trainedModel, single(test.X) );
%             prediction = str2double(cell2mat(predict(trainedModel,(temp_window(:,1:2)))));
        else
            test.X = temp_window(:,features_training);
            prediction = SQBMatrixPredict( trainedModel, single(test.X) );
%             prediction = str2double(cell2mat(predict(trainedModel,(temp_window(:,[1:2,5:6])))));
        end
        
        %add value to the voteIndex
        if prediction <0
            vote(voteIndex) = 0;            
        else
            vote(voteIndex) = 1;
        end
        voteCounts = histcounts(vote(voteIndex - maxVotes: voteIndex));
        voteIndex = voteIndex + 1;

        if (length(voteCounts) >1 && voteCounts(1) > voteCounts (2)) || (length(voteCounts) == 1 && vote(voteIndex - 1) == 0)
            
            %chek final class prediction result
            if jj == length(temp_var_norm)-samples_in_window
                if ~isequal(sep_file_name{3}, 'avoid')
                    wrong_class = wrong_class + 1;
                    wrong_class_details(pp,nn) = ii;
                    pp = pp + 1;
                end
            end
            if first_time == 0 
                class_change = class_change + 1;
                first_time = 1;
            end
%             if class_change>0
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                figure(1)
    %             subplot(121)
                p1=plot((jj:jj+samples_in_window-1),temp_var_norm(jj:jj+samples_in_window-1),'g','LineWidth',2);
                hold on
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%             end
%         elseif prediction == 1
%             figure(1)
% %             subplot(121)
%             p2=plot((jj:jj+samples_in_window-1),temp_var_norm(jj:jj+samples_in_window-1),'k','LineWidth',2);
%             hold on
        elseif (length(voteCounts) > 1 && voteCounts(1) < voteCounts (2)) || (length(voteCounts) == 1 && vote(voteIndex - 1) == 1)
                       
            if first_time == 1   
                if ~isequal(sep_file_name{3}, 'avoid')
                    engageOccured = true;
                end
                engage_frame = jj;
                first_time = 0;
                class_change = class_change + 1;
            end
            
            if jj == length(temp_var_norm)-samples_in_window
                if isequal(sep_file_name{3}, 'avoid')
                    wrong_class = wrong_class + 1;
                    wrong_class_details(pp,nn) = ii;
                    pp = pp + 1;
                end
            end
%             if class_change>0   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                figure(1)
    %             subplot(121)
                p3=plot((jj:jj+samples_in_window-1),temp_var_norm(jj:jj+samples_in_window-1),'r','LineWidth',2);
                hold on
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%             end
        end
        clear temp_window;
    end
%     if (wrong_class>0)

%     if class_change>0
%         figure(1)
%         plot(jj+samples_in_window-1,temp_var_norm(jj+samples_in_window-1,1),'s','MarkerFaceColor',[1 1 0])
%         text(jj+samples_in_window-1,temp_var_norm(jj+samples_in_window-1,1),num2str(ii))
%     end
    if engageOccured == true
%         if intension_frames(ii) == 0
%             intension_frames(ii) = length(temp_var_norm);
%         end
%         engage_frame_total = 0;
        kk=kk+1;
%         engage_frame_total = [engage_frame_total, (intension_frames(kk) - engage_frame)];
    end
    clear temp_var_norm;
    
    if class_change>0
        class_change_total = class_change_total + class_change;
        class_change_details = [class_change_details;ii class_change];    
    end
%     class_change_total/ii
end
end
clear temp_var_norm;

end
nn = nn +1;
wrong_class_details
% end

T = table(mean(engage_frame_total),(mean(engage_frame_total)/30),wrong_class,class_change_total/length(fields_BB),'VariableNames',{'Mean advance prediction frame','Mean advance prediction time (s)','Misclassification','Mean Change of class'}); 
disp(T) 
% save(strcat('output_onlyChanged_',classifier,'_',features,'_',num2str(samples_in_window),'_SF_',num2str(shrinkageFactorValues),'_mD_',num2str(maxTreeDepthValues),'_SS_',num2str(subSamplevalues),'.mat'),'T','class_change_details');

grid on
title('Predicted Results')
xlabel('Frames')
ylabel('Magnitude')