%% "Solving" Monopoly"
%
% Author: Aleksejus Kononovicius
%

clear;

%% Building template for the roll

two_die_roll = [0:6 5:-1:1] ./ 36;
two_die_roll_mat = repmat(two_die_roll, 40, 1);

%% Building transition matrix

transition_matrix = zeros(41);
temp_matrix = full(spdiags(two_die_roll_mat, ...
    1:size(two_die_roll_mat, 2), 40, 2*40));
temp_matrix = temp_matrix(1:40, 1:40) + temp_matrix(1:40, 41:80);
transition_matrix(1:40, 1:40) = temp_matrix;

%% Dealing with "Go To Jail" square

transition_matrix(:, 41) = transition_matrix(:, 31);
transition_matrix(:, 31) = 0;
transition_matrix(31, :) = 0;
transition_matrix(41, :) = transition_matrix(11, :);

%% Dealing with "Chance" cards

chance_squares = [8, 23, 37];
destination_squares = [1, 6, 12, 22, 40, 41, -1, -2, -2, -3];
true_dest = 0;

for sq = chance_squares
    % go to go, reading, St. Charles, Illinois, Boardwalk, Jail, nearest
    % utility, nearest railroad x2, back 3 spaces
    for dest = destination_squares
        true_dest = dest;
        if dest == -3 % back 3 spaces
            true_dest = sq - 3;
        elseif dest == -2 % nearest rail road
            if sq > 6 && sq < 16
                true_dest = 16;
            elseif sq > 16 && sq < 26
                true_dest = 26;
            elseif sq > 26 && sq < 36
                true_dest = 36;
            else
                true_dest = 6;
            end
        elseif dest == -1 % nearest utility
            if sq > 13 && sq < 29
                true_dest = 29;
            else
                true_dest = 13;
            end
        end
        transition_matrix(:, true_dest) = transition_matrix(:, true_dest) + ...
            (1/16)*transition_matrix(:, sq);
    end
    % stay
    transition_matrix(:, sq) = (6/16)*transition_matrix(:, sq);
end

%% Dealing with "Community chest" cards

community_squares = [3, 18, 34];
destination_squares = [1, 41];

for sq = community_squares
    % go to go or jail
    for dest = destination_squares
        transition_matrix(:, dest) = transition_matrix(:, dest) + ...
            (1/16)*transition_matrix(:, sq);
    end
    % stay
    transition_matrix(:, sq) = (14/16)*transition_matrix(:, sq);
end

%% Testing transition matrix

test_condition = all( (abs(sum(transition_matrix, 2) - 1) < 1e-6) | ...
    (abs(sum(transition_matrix, 2)) < 1e-6) );
assert(test_condition, "Some of the rows do not sum to 0 or 1.");

%% Translate my transition matrix into a proper linear algebra transition matrix

proper_transition_matrix = transition_matrix.';

%% Get stationary distribution

[eigen_vectors, eigen_values] = eig(proper_transition_matrix);
mask = find(abs(diag(eigen_values) - 1) < 1e-6);
stationary_dist = eigen_vectors(:, mask).^2;
stationary_dist(11) = stationary_dist(11) + stationary_dist(41);
stationary_dist = stationary_dist(1:40);

bar(stationary_dist)

%% Probability to visit a property of certain color

prob_brown = sum(stationary_dist([2 4]))*100;
prob_cyan = sum(stationary_dist([7 9 10]))*100;
prob_magenta = sum(stationary_dist([12 14 15]))*100;
prob_orange = sum(stationary_dist([17 19 20]))*100;
prob_red = sum(stationary_dist([22 24 25]))*100;
prob_yellow = sum(stationary_dist([27 28 30]))*100;
prob_green = sum(stationary_dist([32 33 35]))*100;
prob_blue = sum(stationary_dist([38 40]))*100;

fprintf('Probability to visit brown: %.2f%%\n', prob_brown);
fprintf('Probability to visit cyan: %.2f%%\n', prob_cyan);
fprintf('Probability to visit magenta: %.2f%%\n', prob_magenta);
fprintf('Probability to visit orange: %.2f%%\n', prob_orange);
fprintf('Probability to visit red: %.2f%%\n', prob_red);
fprintf('Probability to visit yellow: %.2f%%\n', prob_yellow);
fprintf('Probability to visit green: %.2f%%\n', prob_green);
fprintf('Probability to visit blue: %.2f%%\n', prob_blue);

%% Ranking

[~, sorted_indices] = sort(stationary_dist, 'descend');

for idx = sorted_indices.'
    fprintf('%2d   %4.2f%%\n', idx, stationary_dist(idx)*100);
end

