%% Solving "linear" game
%
% Author: Aleksejus Kononovicius
%

clear;

N_SQUARES = 9;

%% Building template for the roll

standard_roll = ones([1,6]) / 6;
standard_roll_mat = repmat(standard_roll, N_SQUARES, 1);

%% Building transition matrix

transition_matrix = full(spdiags(standard_roll_mat, ...
    1:size(standard_roll_mat, 2), N_SQUARES, N_SQUARES));
transition_matrix(:, end) = 1 - sum(transition_matrix(:, 1:(end-1)), 2);

%% Testing transition matrix

test_condition = all(abs(sum(transition_matrix, 2) - 1) < 1e-6);
assert(test_condition, "Some of the rows do not sum to 1.");

%% Translate my transition matrix into a proper linear algebra transition matrix

proper_transition_matrix = transition_matrix.';

%% When the game will end?

state_vector = zeros([N_SQUARES, 1]);
state_vector(1) = 1;

finished = zeros([1, N_SQUARES-1]);
for roll_idx = 1:length(finished)
    state_vector = proper_transition_matrix * state_vector;
    finished(roll_idx) = state_vector(N_SQUARES);
end

figure(1)
subplot(121)
plot(1:length(finished), finished, "k:o")
subplot(122)
plot(1:length(finished), diff([0 finished]), "k:o")
