/**
 * Sample React Native App
 * https://github.com/facebook/react-native
 *
 * @format
 */

import { NewAppScreen } from '@react-native/new-app-screen';
import { StatusBar, StyleSheet, useColorScheme, View, Text, NativeModules, Button, NativeEventEmitter } from 'react-native';
import {
  SafeAreaProvider,
  useSafeAreaInsets,
} from 'react-native-safe-area-context';
import { useEffect } from 'react';

const {CalendarModule} = NativeModules;
const eventEmitter = new NativeEventEmitter(CalendarModule);

function App() {
  const isDarkMode = useColorScheme() === 'dark';

  useEffect(() => {
  const sub1 = eventEmitter.addListener("WebSocketEvent", (e) => console.log("Status:", e));
  const sub2 = eventEmitter.addListener("WebSocketMessage", (e) => console.log("Message:", e));
  const sub3 = eventEmitter.addListener("WebSocketError", (e) => console.log("Error:", e));

  return () => {
    sub1.remove();
    sub2.remove();
    sub3.remove();
  };
}, []);

  const onPress = () => {
    console.log("lokesh")
    console.log(CalendarModule, "logging calendar module")
    // WebSocketModule.startWebSocket('wss://heru-refract-dev-pubsub.webpubsub.azure.com/client/hubs/refractionhub?access_token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjpbIndlYnB1YnN1Yi5qb2luTGVhdmVIdWIiXSwiaWF0IjoxNzU4ODY4NDEwLCJleHAiOjE3NTg5NTQ4MTAsImF1ZCI6Imh0dHBzOi8vaGVydS1yZWZyYWN0LWRldi1wdWJzdWIud2VicHVic3ViLmF6dXJlLmNvbS9jbGllbnQvaHVicy9yZWZyYWN0aW9uaHViIiwic3ViIjoicmVmcmFjdC1kZXZpY2V8MTk3MXwzU1NSLVJORDQtMDAyNCJ9.hrmzBUqjFqolMEaqhoAICOVvp_a4CpJWcKIF8OW83bY')
    CalendarModule.createCalendarEvent('wss://heru-refract-dev-pubsub.webpubsub.azure.com/client/hubs/refractionhub?access_token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjpbIndlYnB1YnN1Yi5qb2luTGVhdmVIdWIiXSwiaWF0IjoxNzU5MDMxNTEyLCJleHAiOjE3NTkxMTc5MTIsImF1ZCI6Imh0dHBzOi8vaGVydS1yZWZyYWN0LWRldi1wdWJzdWIud2VicHVic3ViLmF6dXJlLmNvbS9jbGllbnQvaHVicy9yZWZyYWN0aW9uaHViIiwic3ViIjoicmVmcmFjdC1kZXZpY2V8MTk3MXwzU1NSLVJORDQtMDAyNCJ9.VvDjA6B0TlENLlBAFPTOCJAQ2I6COJ_rAkW37XmRqTs');
  };

  return (
    <SafeAreaProvider>
      <StatusBar barStyle={isDarkMode ? 'light-content' : 'dark-content'} />
      {/* <AppContent /> */}
      <View style={{ padding: 50 }}>
        <Text style={{ color: "white" }}>Lokesh</Text>
        <Button
          onPress={onPress}
          title="Press Me"
          color="#841584" // Optional: customize button color
        />
      </View>
    </SafeAreaProvider>
  );
}

function AppContent() {
  const safeAreaInsets = useSafeAreaInsets();

  return (
    <View style={styles.container}>
      <NewAppScreen
        templateFileName="App.tsx"
        safeAreaInsets={safeAreaInsets}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
});

export default App;
