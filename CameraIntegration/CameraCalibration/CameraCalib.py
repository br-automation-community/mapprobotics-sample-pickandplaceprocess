import numpy as np
import matplotlib.pyplot as plt

# Detected objects in pixel  
pixels = np.array([
    [589.32, 220.61],
    [597.67, 496.44],
    [871.69, 226.67],
    [870.99, 495.45],
    [505.44, 218.49],
    [511.88, 495.13],
    [788.17, 225.5],
    [787.43, 494.3],
    [387.65, 217.63],
    [394.51, 494.22],
    [670.11, 224.76],
    [668.37, 492.56],
    [802.05, 222.23],
    [809.87, 494.88],
    [1085.71, 226.4],
    [1084.75, 496.69]
])
#  Detected object in  gTrackingPath_2 coordinate system
coordinates_mm = np.array([
    [996.88, -50],
    [996.88,   0],
    [946.88,  -50],
    [946.88,    0],
    [1012.00, -50],
    [1012.00,   0],
    [962.00, -50],
    [962.00,   0],
    [1033.00, -50],
    [1033.00,   0],
    [983.00, -50],
    [983.00,   0],
    [958.44,  -50],
    [958.44,    0],
    [908.44,  -50],
    [908.44,    0]
])

# Add the column for translation
A = np.hstack([pixels, np.ones((pixels.shape[0], 1))])

# Compute the affine transformation matrix pixel -> mm
M, residuals, rank, s = np.linalg.lstsq(A, coordinates_mm, rcond=None)

# Compute the estimated mm coordinates
coordinates_mm_estimated = np.dot(A, M)

# Compute the estimation errors
errors = coordinates_mm - coordinates_mm_estimated
error_magnitude = np.linalg.norm(errors, axis=1)

# Compute standard deviation and RMSE
std_dev = np.std(errors, axis=0)
rmse = np.sqrt(np.mean(errors**2, axis=0))

print("Affine transformation matrix (pixel -> mm):")
print(M)
print("\nStandard deviation of errors (mm):", std_dev)
print("RMSE (mm):", rmse)
print("\nPointwise errors for each point (mm):")
for i, (ex, ey) in enumerate(errors):
    print(f"Point {i+1}: Error X = {ex:.3f}, Error Y = {ey:.3f}, Magnitude = {error_magnitude[i]:.3f}")

# Visualization of errors in the image plane
plt.figure(figsize=(8,6))
sc = plt.scatter(pixels[:,0], pixels[:,1], c=error_magnitude, s=100 + 500*error_magnitude, cmap='Reds', edgecolor='k')
plt.colorbar(sc, label='Estimation error (mm)')
plt.xlabel('Pixel X')
plt.ylabel('Pixel Y')
plt.title('Distribution of estimation error in the image plane')
for i, txt in enumerate(range(1, len(pixels)+1)):
    plt.annotate(txt, (pixels[i,0], pixels[i,1]), textcoords="offset points", xytext=(0,5), ha='center', fontsize=8)
plt.gca().invert_yaxis()
plt.grid(True)
plt.tight_layout()
plt.show()

# Origin of the image frame in the object reference frame (where pixel (0,0) maps in mm)
origin_mm = M[2,:]

# Orientation vectors of the pixel axes in mm
# x_axis_mm: vector from origin_mm to where pixel (1,0) would map in mm
x_axis_mm = M[0,:]
# y_axis_mm: vector from origin_mm to where pixel (0,1) would map in mm
y_axis_mm = M[1,:]

# Rotation angle of the image x axis in the object frame (degrees)
angle_rad = np.arctan2(M[1,0], M[0,0])
angle_deg = np.degrees(angle_rad)

print("Origin of image frame in object reference frame (mm):", origin_mm)
print("Pixel X axis vector in mm:", x_axis_mm)
print("Pixel Y axis vector in mm:", y_axis_mm)
print("Rotation angle of image X axis (deg):", angle_deg)