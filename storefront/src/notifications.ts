const notificationStore = {
  swRegistration: null as ServiceWorkerRegistration | null,
  resolve: () => {},
};
const waiting = new Promise<void>(resolve => {
  notificationStore.resolve = resolve;
});

export function setSwRegistration(swRegistration: ServiceWorkerRegistration | null) {
  notificationStore.swRegistration = swRegistration;
  notificationStore.resolve();
}

export async function getActiveSwRegistration() {
  if (notificationStore.swRegistration) {
    return notificationStore.swRegistration;
  } else {
    await waiting;
    if (!notificationStore.swRegistration) {
      throw new Error("Service worker registration is not available");
    }
    return notificationStore.swRegistration;
  }
}
