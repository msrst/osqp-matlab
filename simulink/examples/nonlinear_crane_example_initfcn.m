%% The horizon length and problem size
N = 5;
nx = 6;
nu = 2;


%% Initial condition
% State vector: [x_c, v_c, x_l, v_l, theta, omega]
x0 = zeros(nx, 1);
x0(3) = 0.95;

% Input vector: [u_c, u_l]
u0 = zeros(nu, 1);


%% Constants for the overhead crane
tau_c = 0.13;
tau_l = 0.07;
g = 9.81;
m = 1318.0;


%% Form the non-zero pattern for the dynamics matrix
Adyn_nz = sparse(nx, nx);
Adyn_nz(1, 2) = 1;
Adyn_nz(2, 2) = 1;
Adyn_nz(6, 2) = 1;
Adyn_nz(6, 3) = 1;
Adyn_nz(3, 4) = 1;
Adyn_nz(4, 4) = 1;
Adyn_nz(6, 4) = 1;
Adyn_nz(6, 5) = 1;
Adyn_nz(5, 6) = 1;
Adyn_nz(6, 6) = 1;

Bdyn_nz = sparse(nx, nu);
Bdyn_nz(2, 1) = 1;
Bdyn_nz(6, 1) = 1;
Bdyn_nz(4, 2) = 1;


%% Form the non-zero pattern for the stage constraints (only upper/lower bounds)
E = sparse(2, nx+nu);
E(1, 7) = 1;
E(2, 8) = 1;

ls = [-0.15;
      -0.15];
us = [0.15;
      0.15];

lineq = repmat(ls, N, 1);
uineq = repmat(us, N, 1);


l = [-x0;
     zeros(N*nx, 1);
     lineq];

u = [-x0;
     zeros(N*nx, 1);
     uineq];
     

%% Create the entire non-zero pattern matrix for the constraints
I = speye(nx);
Z = sparse(nx, nu);
comp1 = [-I, Z];
comp2 = [Adyn_nz, Bdyn_nz];

% Create the main part of the Matrix
Anz = speye(N+1);
Anz = kron(Anz,comp1);

% Remove the last columns
Anz = Anz(:, 1:(end-nu));

% Add in the system dynamics
G = speye(N);
G = kron(G, comp2);
[~, c] = size(Anz);
Z1 = sparse( nx, c);
Z2 = sparse(nx*N, nx);
G = [Z1;
      G, Z2];
Anz = Anz + G;

% Add in the inequality constraints
Aineq = speye(N-1);
Aineq = kron( Aineq, E );
Aineq = blkdiag( E(1:nu, :), Aineq, E(1:nu, 1:nx) );

[t, ~] = size(Aineq);
Aineq = Aineq(1:1:(t-nu), :);

Anz = [Anz;
       Aineq];


%% Create the non-zero pattern matrix for the cost
Q = speye(nx);
R = speye(nu);

Pnz = kron( speye(N), blkdiag(Q, R) );
Pnz = blkdiag( Pnz, Q );

P_nz_idx = ( 1:1:nnz( Pnz ) );
A_nz_idx = ( 1:1:nnz( Anz ) );

q = zeros( 1, length(Pnz) );


%% Initialize the trajectory ZoH
traj_0 = repmat( [x0; u0], N+1, 1 );
traj_0 = traj_0( 1:1:(length(traj_0)-nu), : );