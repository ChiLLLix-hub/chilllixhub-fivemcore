// Utility functions for NUI callbacks
export const fetchNui = (eventName, data = {}) => {
  return fetch(`https://${GetParentResourceName()}/${eventName}`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(data),
  })
    .then(resp => resp.json())
    .catch(err => {
      console.error(`Error fetching NUI event ${eventName}:`, err);
      return null;
    });
};

// Check if we're in FiveM environment
export const isEnvBrowser = () => !(window && window.invokeNative);

// Get the resource name
function GetParentResourceName() {
  let resourceName = 'qb-vehicleshop';
  if (!isEnvBrowser()) {
    resourceName = window.GetParentResourceName ? window.GetParentResourceName() : 'qb-vehicleshop';
  }
  return resourceName;
}

// Format currency
export const formatCurrency = (amount) => {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    minimumFractionDigits: 0,
  }).format(amount);
};

// Format vehicle name
export const formatVehicleName = (name) => {
  return name
    .split(/(?=[A-Z])/)
    .map(word => word.charAt(0).toUpperCase() + word.slice(1).toLowerCase())
    .join(' ');
};

// Debug log
export const debugLog = (...args) => {
  if (isEnvBrowser()) {
    console.log('[VehicleShop NUI]', ...args);
  }
};
