import os
import numpy as np
import tensorflow as tf
import cv2
from mtcnn import MTCNN
from src.siamese_model import create_encoder
from keras import optimizers

# Setup Paths,where we will save the trained model weights, and adjust path to reach the LFW dataset folder
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DATASET_PATH = os.path.join(BASE_DIR, "..", "..", "lfw-deepfunneled", "lfw-deepfunneled")
WEIGHTS_SAVE_PATH = os.path.join(BASE_DIR, "..", "weights", "student_face_final.weights.h5")

# Training Parameters
IMG_SIZE = (160, 160)  # FaceNet standard input size
EPOCHS = 30
BATCH_SIZE = 16 
LEARNING_RATE = 1e-5
MARGIN = 1.0  # Gap for triplet loss

# Load MTCNN face detector
detector = MTCNN()

def load_and_crop_face(path, augment=False):
    # Load image and handle missing files
    img = cv2.imread(path)
    if img is None:
        return None
    
    # Convert BGR to RGB since MTCNN needs RGB format
    img_rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
    
    # Detect faces using MTCNN
    try:
        detections = detector.detect_faces(img_rgb)
    except Exception:
        return None
    
    # If a face is found, crop it to focus on facial features
    if len(detections) > 0:
        x, y, w, h = detections[0]['box']
        # Boundary check
        x, y = max(0, x), max(0, y)
        img_rgb = img_rgb[y:y+h, x:x+w]
    
    # Resize to target size
    img_rgb = cv2.resize(img_rgb, IMG_SIZE)

    #Data Augmentation to make the model more robust
    if augment:
        #  horizontal flip
        if np.random.random() > 0.5:
            img_rgb = cv2.flip(img_rgb, 1)
        #  brightness adjustment
        brightness = np.random.uniform(0.8, 1.2)
        img_rgb = np.clip(img_rgb * brightness, 0, 255).astype(np.uint8)
    
    # Normalize pixel values to [0, 1]
    return (img_rgb / 255.0).astype('float32')

def create_triplets(dataset_path):
    #Logic to create (Anchor, Positive, Negative) samples
    anchors, positives, negatives = [], [], []
    classes = [d for d in os.listdir(dataset_path) if os.path.isdir(os.path.join(dataset_path, d))]
    
    if len(classes) < 2:
        raise ValueError("Dataset must have at least 2 different persons")
    
    for i, person in enumerate(classes):
        person_path = os.path.join(dataset_path, person)
        images = [os.path.join(person_path, f) for f in os.listdir(person_path) if f.lower().endswith(('.png', '.jpg', '.jpeg', '.ppm', '.pgm', '.pbm', '.tif', '.tiff'))]
        
        if len(images) < 2:
            continue
        
        # Use each image as anchor once, pick positive from remaining
        for img_a_path in images:
            a_img = load_and_crop_face(img_a_path, augment=True)
            if a_img is None:
                continue
            
            # Positive: another image from the same person
            remaining_images = [x for x in images if x != img_a_path]
            if not remaining_images:
                continue
            p_img_path = np.random.choice(remaining_images)
            p_img = load_and_crop_face(p_img_path, augment=True)
            
            if p_img is None:
                continue
            
            # Negative: image from a different person pick a random different person
            
            neg_indices = [j for j in range(len(classes)) if j != i]
            if not neg_indices:
                continue
            neg_person_idx = np.random.choice(neg_indices)
            neg_person = classes[neg_person_idx]
            neg_path = os.path.join(dataset_path, neg_person)
            neg_images = [f for f in os.listdir(neg_path) if f.lower().endswith(('.png', '.jpg', '.jpeg', '.ppm', '.pgm', '.pbm', '.tif', '.tiff'))]
            
            if not neg_images:
                continue
            
            n_img_path = os.path.join(neg_path, np.random.choice(neg_images))
            n_img = load_and_crop_face(n_img_path, augment=True)
            
            if n_img is not None:
                anchors.append(a_img)
                positives.append(p_img)
                negatives.append(n_img)
    
    if len(anchors) == 0:
        raise ValueError("No valid triplets could be created. Check dataset and face detection.")
    
    return np.array(anchors), np.array(positives), np.array(negatives)

def triplet_loss(anchor, positive, negative):
    
    pos_dist = tf.reduce_sum(tf.square(anchor - positive), axis=-1)
    neg_dist = tf.reduce_sum(tf.square(anchor - negative), axis=-1)
    return tf.reduce_mean(tf.maximum(pos_dist - neg_dist + MARGIN, 0.0))

@tf.function
def train_step(encoder, optimizer, batch):
    
    with tf.GradientTape() as tape:
        a, p, n = batch
        emb_a, emb_p, emb_n = encoder(a), encoder(p), encoder(n)
        loss = triplet_loss(emb_a, emb_p, emb_n)
    
    grads = tape.gradient(loss, encoder.trainable_variables)
    optimizer.apply_gradients(zip(grads, encoder.trainable_variables))
    return loss

def main():
    print(f"Initializing data pipeline from: {DATASET_PATH}")
    print(f"Dataset path exists: {os.path.exists(DATASET_PATH)}")
   
    # Count available classes
    if os.path.exists(DATASET_PATH):
        classes = [d for d in os.listdir(DATASET_PATH) if os.path.isdir(os.path.join(DATASET_PATH, d))]
        print(f"Found {len(classes)} classes in dataset")
   
    encoder = create_encoder()
    opt = optimizers.Adam(LEARNING_RATE)
    
    for epoch in range(EPOCHS):
        print(f"Creating triplets for epoch {epoch+1}...")
        a, p, n = create_triplets(DATASET_PATH)
        print(f"Created {len(a)} triplets")
        
        indices = np.random.permutation(len(a))
        total_loss = 0
        num_batches = 0
        
        for i in range(0, len(a), BATCH_SIZE):
            idx = indices[i:i+BATCH_SIZE]
            if len(idx) < BATCH_SIZE:
                continue
            loss = train_step(encoder, opt, (a[idx], p[idx], n[idx]))
            total_loss += loss.numpy()
            num_batches += 1
        
        avg_loss = total_loss / num_batches if num_batches > 0 else 0
        print(f"Epoch {epoch+1}/{EPOCHS} | Convergence Loss: {avg_loss:.4f}")
    
    os.makedirs(os.path.dirname(WEIGHTS_SAVE_PATH), exist_ok=True)
    encoder.save_weights(WEIGHTS_SAVE_PATH)
    print(f"✨ Model serialization complete: {WEIGHTS_SAVE_PATH}")

if __name__ == "__main__":
    main()


