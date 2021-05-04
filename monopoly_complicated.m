%% Solving a bit more "complicated" version of Monopoly
%
% Author: Aleksejus Kononovicius
%
% This "solution" of Monopoly includes few more complicated things:
% speeding rule (if you roll doubles three times in a row, you go to jail),
% complicated jail mechanics (stay in jail until you roll doubles or for no
% more than 3 turns). Also you can enable and disable some of the rules
%
% This was not coded during the lecture. It was coded off camera.

clear;

%% Enable/disable rules as you like

use_go_to_jail = true; % use "go to jail" square? or ignore its special effect
use_chance = true; % use chance cards
use_community = true; % use community cards
use_speeding = true; % roll doubles three times in a row -> go to jail
long_term_jail = true; % stay in jail for 3 turns or leave immediately

%% Initialize transition matrix

% The board contains 40 squares + 1 special "in jail square". So the
% simplest transition matrix would be 41x41 matrix, but we want to deal with
% other more complicated rules here.
%
% We take into account speeding rule by adding 80 new states, which we label
% from 41 to 120. Now the meaning of the states is this:
% * 1-40 states correspond to ordinary squares.
% * 41-80 states correspond to ordinary squares, if the player has rolled
%   doubles once previously.
% * 81-120 states correspond to ordinary squares, if the player has rolled
%   doubles twice previously.
% Effectively the state is encoded like this:
%
%   state = true_position + 40*times_rolled_doubles
%
% If the player is sent to jail (for example by rolling doubles three
% times), the player is sent to state 121. Player may leave only by rolling
% doubles. If player rolls well we assume that player leaves from 11th
% square (state 51)). If player doesn't roll well, the player is moved to
% state 122. On the second turn, the player still must roll doubles or move
% to state 123. On the third turn player either rolls double and leaves as
% before or rolls non-doubles and leaves from state 11.
%
% So we need all 123 rows and columns.

transition_matrix = zeros(123);

%% Setup roll templates

% ordinary rolls is a roll, which didn't result in doubles
ordinary_roll = [0 1:6 5:-1: 1];
ordinary_roll(2:2:12) = ordinary_roll(2:2:12) - 1;
ordinary_roll = ordinary_roll / 36;

ordinary_roll_mat = repmat(ordinary_roll, [40, 1]);
ordinary_roll_mat = full(spdiags(ordinary_roll_mat, 1:12, 40, 80));
ordinary_roll_mat = ordinary_roll_mat(1:40, 1:40) + ordinary_roll_mat(1:40, 41:80);
clear ordinary_roll;

% double roll is a roll which did result in doubles
double_roll = zeros([1, 12]);
double_roll(2:2:12) = 1;
double_roll = double_roll / 36;

double_roll_mat = repmat(double_roll, [40, 1]);
double_roll_mat = full(spdiags(double_roll_mat, 1:12, 40, 80));
double_roll_mat = double_roll_mat(1:40, 1:40) + double_roll_mat(1:40, 41:80);
clear double_roll;

%% What happens if we make a roll

if use_speeding
    % if there was no previous double roll
    %   then we move from some state in [1, 40] to some state in [1, 40]
    transition_matrix(1:40, 1:40) = ordinary_roll_mat;
    %   unless it was a double roll, in which case we move to some state in
    %   [41, 80]
    transition_matrix(1:40, 41:80) = double_roll_mat;
    
    % if there was a single previous double roll
    %   then we move from some state in [41, 80] to some state in [1, 40]
    transition_matrix(41:80, 1:40) = ordinary_roll_mat;
    %   unless it was a double roll, in which case we move to some state in
    %   [81, 120]
    transition_matrix(41:80, 81:120) = double_roll_mat;
    
    % if there were two previous double rolls
    %   then we move from some state in [81, 120] to some state in [1, 40]
    transition_matrix(81:120, 1:40) = ordinary_roll_mat;
    %   unless it was a double roll, in which case we move to the jail (121)
    transition_matrix(81:120, 121) = 1 - sum(transition_matrix(81:120, 1:120), 2);
else
    transition_matrix(1:40, 1:40) = ordinary_roll_mat + double_roll_mat;
end

% if we are in jail for the first turn
%   then we can get out only by rolling doubles
transition_matrix(121, 1:40) = double_roll_mat(11, :);
%   otherwise we have to update our state to 122 (staying in jail for 2nd
%   turn)
transition_matrix(121, 122) = 1 - sum(transition_matrix(121, 1:120));

% if we are in jail for the second turn
%   then we can get out only by rolling doubles
transition_matrix(122, 1:40) = double_roll_mat(11, :);
%   otherwise we have to update our state to 123 (staying in jail for 3rd
%   turn)
transition_matrix(122, 123) = 1 - sum(transition_matrix(122, 1:120));

% if we are in jail for the third turn
%   then we can get out by rolling doubles or by rolling an ordinary roll
transition_matrix(123, 1:40) = double_roll_mat(11, :) + ordinary_roll_mat(11, :);

%% Landing into "Go To Jail"

% Landing means that state changes into 31 (0 doubles), 71 (1 double) or
% 111 (2 doubles). We should reroute every landing into 121 state (1st turn
% in jail).
if use_go_to_jail
    transition_matrix(:, 121) = transition_matrix(:, 121) + sum(transition_matrix(:, [31 71 111]), 2);
    transition_matrix(:, [31 71 111]) = 0;
    transition_matrix([31 71 111], :) = 0;
end

%% Landing into "Chance"

if use_chance
    chance_sq = [8, 23, 37];
    
    for sq = chance_sq
        % might get sent to Go (1)
        transition_matrix(:, 1) = transition_matrix(:, 1) + (1/16)*transition_matrix(:, sq);
        transition_matrix(:, 41) = transition_matrix(:, 41) + (1/16)*transition_matrix(:, 40+sq);
        transition_matrix(:, 81) = transition_matrix(:, 81) + (1/16)*transition_matrix(:, 80+sq);
        
        % might get sent to Reading Railroad (6)
        transition_matrix(:, 6) = transition_matrix(:, 6) + (1/16)*transition_matrix(:, sq);
        transition_matrix(:, 46) = transition_matrix(:, 46) + (1/16)*transition_matrix(:, 40+sq);
        transition_matrix(:, 86) = transition_matrix(:, 86) + (1/16)*transition_matrix(:, 80+sq);
        
        % might get sent to St. Charles Place (12)
        transition_matrix(:, 12) = transition_matrix(:, 12) + (1/16)*transition_matrix(:, sq);
        transition_matrix(:, 52) = transition_matrix(:, 52) + (1/16)*transition_matrix(:, 40+sq);
        transition_matrix(:, 92) = transition_matrix(:, 92) + (1/16)*transition_matrix(:, 80+sq);
        
        % might get sent to Illinous Avenue (22)
        transition_matrix(:, 22) = transition_matrix(:, 22) + (1/16)*transition_matrix(:, sq);
        transition_matrix(:, 62) = transition_matrix(:, 62) + (1/16)*transition_matrix(:, 40+sq);
        transition_matrix(:, 102) = transition_matrix(:, 102) + (1/16)*transition_matrix(:, 80+sq);
        
        % might get sent to Broadwalk (40)
        transition_matrix(:, 40) = transition_matrix(:, 40) + (1/16)*transition_matrix(:, sq);
        transition_matrix(:, 80) = transition_matrix(:, 80) + (1/16)*transition_matrix(:, 40+sq);
        transition_matrix(:, 120) = transition_matrix(:, 120) + (1/16)*transition_matrix(:, 80+sq);
        
        % might get sent to Jail (121)
        transition_matrix(:, 121) = transition_matrix(:, 121) + ...
            (1/16)*transition_matrix(:, sq) + ...
            (1/16)*transition_matrix(:, 40+sq) + ...
            (1/16)*transition_matrix(:, 80+sq);
        
        % might get sent to nearest utility (13 or 29)
        if sq > 13 && sq < 29
            transition_matrix(:, 29) = transition_matrix(:, 29) + (1/16)*transition_matrix(:, sq);
            transition_matrix(:, 69) = transition_matrix(:, 69) + (1/16)*transition_matrix(:, 40+sq);
            transition_matrix(:, 109) = transition_matrix(:, 109) + (1/16)*transition_matrix(:, 80+sq);
        else
            transition_matrix(:, 13) = transition_matrix(:, 13) + (1/16)*transition_matrix(:, sq);
            transition_matrix(:, 53) = transition_matrix(:, 53) + (1/16)*transition_matrix(:, 40+sq);
            transition_matrix(:, 93) = transition_matrix(:, 93) + (1/16)*transition_matrix(:, 80+sq);
        end
        
        % might get sent to nearest railroad (6, 16, 26 or 36)
        if sq > 6 && sq < 16
            transition_matrix(:, 16) = transition_matrix(:, 16) + (2/16)*transition_matrix(:, sq);
            transition_matrix(:, 56) = transition_matrix(:, 56) + (2/16)*transition_matrix(:, 40+sq);
            transition_matrix(:, 96) = transition_matrix(:, 96) + (2/16)*transition_matrix(:, 80+sq);
        elseif sq > 16 && sq < 26
            transition_matrix(:, 26) = transition_matrix(:, 26) + (2/16)*transition_matrix(:, sq);
            transition_matrix(:, 66) = transition_matrix(:, 66) + (2/16)*transition_matrix(:, 40+sq);
            transition_matrix(:, 106) = transition_matrix(:, 106) + (2/16)*transition_matrix(:, 80+sq);
        elseif sq > 26 && sq < 36
            transition_matrix(:, 36) = transition_matrix(:, 36) + (2/16)*transition_matrix(:, sq);
            transition_matrix(:, 76) = transition_matrix(:, 76) + (2/16)*transition_matrix(:, 40+sq);
            transition_matrix(:, 116) = transition_matrix(:, 116) + (2/16)*transition_matrix(:, 80+sq);
        else
            transition_matrix(:, 6) = transition_matrix(:, 6) + (2/16)*transition_matrix(:, sq);
            transition_matrix(:, 46) = transition_matrix(:, 46) + (2/16)*transition_matrix(:, 40+sq);
            transition_matrix(:, 86) = transition_matrix(:, 86) + (2/16)*transition_matrix(:, 80+sq);
        end
        
        % might get sent back 3 spaces
        transition_matrix(:, sq-3) = transition_matrix(:, sq-3) + (1/16)*transition_matrix(:, sq);
        transition_matrix(:, 40+sq-3) = transition_matrix(:, 40+sq-3) + (1/16)*transition_matrix(:, 40+sq);
        transition_matrix(:, 80+sq-3) = transition_matrix(:, 80+sq-3) + (1/16)*transition_matrix(:, 80+sq);
        
        % or stay
        transition_matrix(:, sq) = (6/16)*transition_matrix(:, sq);
        transition_matrix(:, 40+sq) = (6/16)*transition_matrix(:, 40+sq);
        transition_matrix(:, 80+sq) = (6/16)*transition_matrix(:, 80+sq);
    end
    clear chance_sq sq;
    
end

%% Landing into "Community chest"

if use_community
    community_chest_sq = [3, 18, 34];
    
    for sq = community_chest_sq
        % might get sent to Go (1)
        transition_matrix(:, 1) = transition_matrix(:, 1) + (1/16)*transition_matrix(:, sq);
        transition_matrix(:, 41) = transition_matrix(:, 41) + (1/16)*transition_matrix(:, 40+sq);
        transition_matrix(:, 81) = transition_matrix(:, 81) + (1/16)*transition_matrix(:, 80+sq);
    
        % or Jail (121)
        transition_matrix(:, 121) = transition_matrix(:, 121) + ...
            (1/16)*transition_matrix(:, sq) + ...
            (1/16)*transition_matrix(:, 40+sq) + ...
            (1/16)*transition_matrix(:, 80+sq);
        
        % or stay
        transition_matrix(:, sq) = (14/16)*transition_matrix(:, sq);
        transition_matrix(:, 40+sq) = (14/16)*transition_matrix(:, 40+sq);
        transition_matrix(:, 80+sq) = (14/16)*transition_matrix(:, 80+sq);
    end
    
    clear community_chest_sq sq;
    
end

%% Short term Jail

% lets assume that the player pays immediately, so is able to resume from
% 123 (3rd turn in jail)
if ~long_term_jail
    transition_matrix(121, :) = transition_matrix(123, :);
    transition_matrix(122, :) = 0;
    transition_matrix(123, :) = 0;
end

%% Check the transition matrix

sums = sum(transition_matrix, 2);
mask = (abs(sums - 1) < 1e-6) | (abs(sums) < 1e-6);
assert(all(mask), 'Some rows do not add up to 0 or 1.');
clear sums mask;

figure(1);
clf();
imagesc(transition_matrix);
xlabel('Destination');
ylabel('Source');
set(gca, 'TickDir', 'Out');

%% The stationary distribution

[eigen_vectors, eigen_values] = eig(transition_matrix');
stationary_dist = eigen_vectors(:, (abs(eigen_values - 1) < 1e-6)).^2;
stationary_dist(1:40) = stationary_dist(1:40) + stationary_dist(41:80) + stationary_dist(81:120);
stationary_dist(41) = sum(stationary_dist(121:123));
stationary_dist = stationary_dist(1:41);
clear eigen_vectors eigen_values;

figure(2);
clf();
plot(stationary_dist);
