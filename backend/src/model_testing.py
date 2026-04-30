import os
import sys
import numpy as np
import cv2
from PIL import Image
from mtcnn import MTCNN
import tensorflow as tf
from siamese_model import create_encoder
import pandas as pd
from sklearn.metrics import accuracy_score, precision_score, recall_score, f1_score, classification_report, confusion_matrix
import matplotlib.pyplot as plt
import seaborn as sns
from tqdm import tqdm
import argparse
import logging


logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# Paths 
#NOTE FOR THE TEAM: هينا عدلوا المسارات للمسارات الصحيحه لاماكن الملفات في أجهزتكم
MODEL_PATH = r"D:\IAeetand_system\backend\weights\face_final.weights.h5"
DATASET_DIR = r"D:\IAeetand_system\lfw-deepfunneled"
PAIRS_PATH = r"D:\IAeetand_system\pairs.csv"
THRESHOLD = 1.4

# Add src to path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

# Global model
_model = None

def load_model():
    global _model
    if _model is None:
        logger.info('Building and loading model...')
        _model = create_encoder()
        
        
        if os.path.exists(MODEL_PATH):
            _model.load_weights(MODEL_PATH)
            logger.info(f'SUCCESS: Loaded YOUR weights from: {MODEL_PATH}')
        else:
            
            raise FileNotFoundError(f'CRITICAL ERROR: Could not find weights at {MODEL_PATH}')
            
        _model.trainable = False
    return _model

def extract_vector(image_path):
    try:
        image = Image.open(image_path).convert('RGB')
        image_np = np.array(image)
        detector = MTCNN()
        faces = detector.detect_faces(image_np)
        
        if len(faces) == 0:
            raise ValueError('No face detected')
        
        largest_face = max(faces, key=lambda f: f['confidence'])
        x, y, w, h = largest_face['box']
        
        margin = 0.2
        x1, y1 = max(0, int(x - w * margin)), max(0, int(y - h * margin))
        x2, y2 = min(image_np.shape[1], int(x + w * (1 + margin))), min(image_np.shape[0], int(y + h * (1 + margin)))
        face = cv2.resize(image_np[y1:y2, x1:x2], (160, 160))
        face = face.astype('float32') / 255.0
        
        model = load_model()
        embedding = model.predict(np.expand_dims(face, axis=0), verbose=0)[0]
        return embedding
    except Exception as e:
        raise ValueError(f'Error: {str(e)}')

def get_image_path(name, num):
    if num is None or pd.isna(num):
        return None
    try:
        clean_num = int(float(num))
        return os.path.join(DATASET_DIR, 'lfw-deepfunneled', name, f'{name}_{clean_num:04d}.jpg')
    except:
        return None

def evaluate(num_pos=200, num_neg=200, threshold=1.4):
    logger.info(f'Starting evaluation: {num_pos} pos + {num_neg} neg')
    df = pd.read_csv(PAIRS_PATH)
    pos_pairs = df.iloc[:3000].values
    neg_pairs = df.iloc[3000:].values
    
    # Sampling
    pos_sample = pos_pairs[np.random.choice(len(pos_pairs), num_pos, replace=False)]
    neg_sample = neg_pairs[np.random.choice(len(neg_pairs), num_neg, replace=False)]
    
    all_pairs = np.vstack([pos_sample, neg_sample])
    initial_labels = [1] * num_pos + [0] * num_neg
    
    embeddings1, embeddings2, final_labels = [], [], []
    
    for i, pair in enumerate(tqdm(all_pairs, desc='Extracting embeddings')):
        p1 = get_image_path(pair[0], pair[1])
        p2 = get_image_path(pair[2], pair[3])
        
        if p1 and p2 and os.path.exists(p1) and os.path.exists(p2):
            try:
                embeddings1.append(extract_vector(p1))
                embeddings2.append(extract_vector(p2))
                final_labels.append(initial_labels[i])
            except:
                continue

    
    dists = np.linalg.norm(np.array(embeddings1) - np.array(embeddings2), axis=1)
    preds = (dists < threshold).astype(int)
    
    acc = accuracy_score(final_labels, preds)
    f1 = f1_score(final_labels, preds)
    
    print(f"\nEvaluation Done!\nAccuracy: {acc:.4f}\nF1-Score: {f1:.4f}")
    
    cm = confusion_matrix(final_labels, preds)
    sns.heatmap(cm, annot=True, fmt='d', cmap='Blues', xticklabels=['Diff', 'Same'], yticklabels=['Diff', 'Same'])
    plt.savefig('confusion_matrix.png')
    logger.info('Results saved to confusion_matrix.png')

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--num-pos', type=int, default=20)
    parser.add_argument('--num-neg', type=int, default=20)
    args = parser.parse_args()
    evaluate(args.num_pos, args.num_neg)