import tensorflow as tf
from keras_facenet import FaceNet
#from tensorflow.keras import layers, Model
from keras import layers, Model
def create_encoder():
    
    # it's the door for the model the image size will be 160X160 and 3 is for the RGB colors
    input_layer = layers.Input(shape=(160, 160, 3), name="face_input")
    
    # Load FaceNet as backbone'the brian' (InceptionResNetV1) 
    facenet = FaceNet()
    # here we get the FaceNet model and freeze it (Partial Training) so those frozen layrs don't be trained
    base_model = facenet.model
    base_model.trainable = False

    # Pass input(image) through FaceNet backbone and and it's output will be 512 number (by deffult) 
    x = base_model(input_layer)
    
    # Custom embedding head for 128-d output and here start the inttelligence we added to our project 
    # Adding additional dense layers for task-specific fine-tuning
    x = layers.Dense(256, activation='relu', name="embedding_dense_1")(x)# relu any nagtive value will converted into zero
    x = layers.BatchNormalization(name="embedding_bn")(x)#it's redistributes the numbers so that the avarge is zero
    x = layers.Dropout(0.3, name="embedding_dropout")(x)#so the model doesn't memorize the images but learns the genaral facial features
    
    x = layers.Dense(128, name="embedding_dense_2")(x)#the model compres everthing it learned into 128 numbers.

    # L2 Normalization to constrain embeddings to a hypersphere (the vactore leangth=1)
    # This ensures embeddings lie on a unit sphere for better distance metrics
    output = layers.UnitNormalization(axis=-1, name="embedding_output")(x)

    model = Model(inputs=input_layer, outputs=output, name="FaceNet_Encoder")
    return model

if __name__ == "__main__":
    encoder = create_encoder()
    print("\n FaceNet Model Architecture Built Successfully.")
    encoder.summary()

