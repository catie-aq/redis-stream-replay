import { Controller } from "stimulus";
import axios from 'axios';

// TODO: Write a manual if this stays in the code base.
export default class extends Controller {
  static targets = [ "output", "hidden", "ratio" ]

  connect() {
    this.name = "unnamed";
    this.url = "/";

    if(this.data.has("url")){
        this.url = this.data.get("url");
     }
    if(this.data.has("name")){
      this.name = this.data.get("name");
    }
  }

  checkStatus(){
    console.log('Checking status...');
    let controller = this;
    axios.get("/reading_ratio")
    .then(function (response) {
      // handle success
      console.log(response);
      // controller.success(response);
      controller.ratioTarget.innerHTML = response.data;
     
    })
    .catch(function (error) {
      // handle error
      console.log(error);
    })
    .then(function () {
      // always executed
    });
  }

  play(target){
      console.log("play:" + this.url);
      let controller = this;
      axios.get("/play")
      .then(function (response) {
        // handle success
        console.log(response);
        // controller.success(response);
        controller.statusChecker = setInterval(controller.checkStatus, 1000);

        setTimeout(() => { clearInterval(controller.statusChecker) }, 6000);

      })
      .catch(function (error) {
        // handle error
        console.log(error);
      })
      .then(function () {
        // always executed
      });
}   

  error(response){
    console.log("Error");
    console.log(response);
    this.outputTarget.innerHTML = response.detail[0];
  }
}
