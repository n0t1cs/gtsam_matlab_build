%% GTSAM MATLAB Toolbox - Basic Test
% This script verifies that GTSAM MATLAB toolbox is correctly installed
% and working properly.
%
% Usage: Run this script to test GTSAM installation
%        >> gtsam_test

clear all; close all;

fprintf('\n');
fprintf('╔════════════════════════════════════════════════════════════════╗\n');
fprintf('║      GTSAM MATLAB Toolbox - Basic Installation Test           ║\n');
fprintf('╚════════════════════════════════════════════════════════════════╝\n');
fprintf('\n');

% Test 1: Check if GTSAM import works
fprintf('[Test 1] Importing gtsam namespace... ');
try
    import gtsam.*
    fprintf('✓ PASSED\n');
except
    fprintf('✗ FAILED\n');
    fprintf('ERROR: Unable to import gtsam. Check installation.\n');
    return;
end

% Test 2: Create basic GTSAM objects
fprintf('[Test 2] Creating basic GTSAM objects... ');
try
    % Create a Pose3 object (6 DOF pose in 3D)
    pose = Pose3();
    fprintf('✓ PASSED\n');
except
    fprintf('✗ FAILED\n');
    fprintf('ERROR: Cannot create Pose3 object\n');
    return;
end

% Test 3: Create a NonlinearFactorGraph
fprintf('[Test 3] Creating NonlinearFactorGraph... ');
try
    graph = NonlinearFactorGraph();
    fprintf('✓ PASSED\n');
except
    fprintf('✗ FAILED\n');
    fprintf('ERROR: Cannot create NonlinearFactorGraph\n');
    return;
end

% Test 4: Create Values object (optimization variable storage)
fprintf('[Test 4] Creating Values object... ');
try
    values = Values();
    fprintf('✓ PASSED\n');
except
    fprintf('✗ FAILED\n');
    fprintf('ERROR: Cannot create Values object\n');
    return;
end

% Test 5: Create a point in 3D
fprintf('[Test 5] Creating 3D Point... ');
try
    point = Point3(1.0, 2.0, 3.0);
    fprintf('✓ PASSED\n');
except
    fprintf('✗ FAILED\n');
    fprintf('ERROR: Cannot create Point3\n');
    return;
end

% Test 6: Create a Rot3 (3D rotation)
fprintf('[Test 6] Creating Rotation (Rot3)... ');
try
    rot = Rot3();
    fprintf('✓ PASSED\n');
except
    fprintf('✗ FAILED\n');
    fprintf('ERROR: Cannot create Rot3\n');
    return;
end

% Test 7: Create a PriorFactor
fprintf('[Test 7] Creating PriorFactor... ');
try
    model = noiseModel.Isotropic.Sigma(6, 0.1);
    prior = PriorFactorPose3(0, pose, model);
    fprintf('✓ PASSED\n');
except
    fprintf('✗ FAILED\n');
    fprintf('ERROR: Cannot create PriorFactor\n');
    return;
end

% Test 8: Insert into factor graph
fprintf('[Test 8] Adding factor to graph... ');
try
    graph.add(prior);
    fprintf('✓ PASSED\n');
except
    fprintf('✗ FAILED\n');
    fprintf('ERROR: Cannot add factor to graph\n');
    return;
end

% Test 9: Insert initial estimate
fprintf('[Test 9] Inserting initial estimate... ');
try
    values.insert(0, Pose3());
    fprintf('✓ PASSED\n');
except
    fprintf('✗ FAILED\n');
    fprintf('ERROR: Cannot insert values\n');
    return;
end

% Test 10: Create an optimizer
fprintf('[Test 10] Creating LevenbergMarquardtOptimizer... ');
try
    params = LevenbergMarquardtParams();
    optimizer = LevenbergMarquardtOptimizer(graph, values, params);
    fprintf('✓ PASSED\n');
except
    fprintf('✗ FAILED\n');
    fprintf('ERROR: Cannot create optimizer\n');
    return;
end

fprintf('\n');
fprintf('╔════════════════════════════════════════════════════════════════╗\n');
fprintf('║                    ALL TESTS PASSED! ✓                         ║\n');
fprintf('║                                                                ║\n');
fprintf('║      GTSAM MATLAB Toolbox is correctly installed and           ║\n');
fprintf('║      ready for use!                                            ║\n');
fprintf('╚════════════════════════════════════════════════════════════════╝\n');
fprintf('\n');
