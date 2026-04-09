import { create } from 'zustand';
import type { Bus, Route } from '../data/mockData';
import { MOCK_ROUTES, INITIAL_BUSES } from '../data/mockData';

export type ScreenType = 'Home' | 'Map' | 'Analytics' | 'Favorites';

export interface Alert {
  id: string;
  busId: string;
  type: 'Stops' | 'Distance' | 'Time' | 'Reached';
  value: number; // e.g., 2 (stops), 500 (meters), 2 (mins)
  message: string;
}

interface AppState {
  currentScreen: ScreenType;
  userLocation: [number, number]; // User's device location
  routes: Route[];
  buses: Bus[];
  selectedRouteId: string | null;
  trackedBusId: string | null; // For Route Details / Tracking view
  customStopLocation: [number, number] | null;
  touristMode: boolean;
  favorites: { routes: string[]; stops: string[] };
  activeAlerts: Alert[];
  triggeredAlerts: string[]; // IDs of alerts that have fired
  
  // Actions
  setScreen: (screen: ScreenType) => void;
  setBuses: (buses: Bus[]) => void;
  setSelectedRoute: (id: string | null) => void;
  setTrackedBus: (id: string | null) => void;
  setCustomStop: (location: [number, number] | null) => void;
  toggleTouristMode: () => void;
  setUserLocation: (location: [number, number]) => void;
  toggleFavoriteRoute: (routeId: string) => void;
  addAlert: (alert: Omit<Alert, 'id'>) => void;
  triggerAlert: (alertId: string) => void;
  removeAlert: (alertId: string) => void;
}

export const useStore = create<AppState>((set) => ({
  currentScreen: 'Home',
  userLocation: [15.498, 73.827], 
  routes: MOCK_ROUTES,
  buses: INITIAL_BUSES,
  selectedRouteId: null,
  trackedBusId: null,
  customStopLocation: null,
  touristMode: false,
  favorites: { routes: ['r1'], stops: ['s1', 's4'] },
  activeAlerts: [],
  triggeredAlerts: [],

  setScreen: (currentScreen) => set({ currentScreen }),
  setBuses: (buses) => set({ buses }),
  setSelectedRoute: (selectedRouteId) => set({ selectedRouteId }),
  setTrackedBus: (trackedBusId) => set({ trackedBusId, currentScreen: trackedBusId ? 'Map' : 'Home' }),
  setCustomStop: (customStopLocation) => set({ customStopLocation }),
  toggleTouristMode: () => set((state) => ({ touristMode: !state.touristMode })),
  setUserLocation: (userLocation) => set({ userLocation }),
  
  toggleFavoriteRoute: (routeId) => set((state) => {
    const isFav = state.favorites.routes.includes(routeId);
    return {
      favorites: {
        ...state.favorites,
        routes: isFav ? state.favorites.routes.filter(id => id !== routeId) : [...state.favorites.routes, routeId]
      }
    };
  }),

  addAlert: (newAlert) => set((state) => ({
    activeAlerts: [...state.activeAlerts, { ...newAlert, id: Date.now().toString() }]
  })),
  
  triggerAlert: (alertId) => set((state) => ({
    triggeredAlerts: [...state.triggeredAlerts, alertId]
  })),

  removeAlert: (alertId) => set((state) => ({
    activeAlerts: state.activeAlerts.filter(a => a.id !== alertId),
    triggeredAlerts: state.triggeredAlerts.filter(id => id !== alertId)
  }))
}));
