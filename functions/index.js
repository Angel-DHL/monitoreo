const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.notificarCambioEstadoUnidad = functions.firestore
  .document("unidades/{unidadId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    if (before.Estado !== after.Estado) {
      const message = {
        notification: {
          title: `Estado actualizado: ${context.params.unidadId}`,
          body: `Nuevo estado: ${after.Estado}`,
        },
        topic: "unidades",
      };

      await admin.messaging().send(message);
    }
  });
