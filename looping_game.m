%% Solving "looping" game
%
% Author: Aleksejus Kononovicius
%

clear;

N_SQUARES = 40;

%% Building template for the roll

standard_roll = ones([1,6]) / 6;
standard_roll_mat = repmat(standard_roll, N_SQUARES, 1);

%% Building transition matrix

transition_matrix = full(spdiags(standard_roll_mat, ...
    1:size(standard_roll_mat, 2), N_SQUARES, 2*N_SQUARES));
transition_matrix = transition_matrix(1:N_SQUARES, 1:N_SQUARES) + ...
    transition_matrix(1:N_SQUARES, (N_SQUARES+1):end);

%% Testing transition matrix

test_condition = all(abs(sum(transition_matrix, 2) - 1) < 1e-6);
assert(test_condition, "Some of the rows do not sum to 1.");

%% Translate my transition matrix into a proper linear algebra transition matrix

proper_transition_matrix = transition_matrix.';

%% How likely we are to see player visiting the 8th square on n-th turn?

state_vector = zeros([N_SQUARES, 1]);
state_vector(1) = 1;

for after_turn = [1, 3, 100, inf]
    if isinf(after_turn)
        [eigen_vectors, eigen_values] = eig(proper_transition_matrix);
        mask = (abs(diag(eigen_values) - 1) < 1e-6);
        stationary_dist = eigen_vectors(:, mask);
        stationary_dist = stationary_dist .^ 2;
        after_given_turn = stationary_dist;
    else % if after_turn is not infinite
        after_given_turn = (proper_transition_matrix^after_turn) * state_vector;
    end
    fprintf('Probability to be at 8th square after %d turn is %.2f%%\n', ...
        after_turn, after_given_turn(8)*100)
end
